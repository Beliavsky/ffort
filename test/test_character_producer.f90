! SPDX-License-Identifier: MIT
! Strict producer CHARACTER rank/type and source length-token regressions.
program test_character_producer
    use fortfront_compiler
    use fortfront_ast, only: subroutine_call_node, declaration_node
    use type_system_unified, only: TCHAR
    implicit none
    character(*),parameter::nl=new_line('a')
    type(compiler_frontend_options_t)::opts
    type(compiler_frontend_result_t)::front
    type(resolved_type_query_t)::typ
    integer::i,found
    opts%input_mode=INPUT_MODE_STANDARD
    opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.
    opts%run_semantics=.true.
    call check('"!"//a',.true.)
    call check('a//"!"',.true.)
    call check('[character(4)::"xyz"]',.true.)
    call check('joined(a,a)',.true.)
    call check('joined(joined(a,a),a)',.true.)
    call check('a(1)',.false.)
    call check('[1,2]',.false.)
    call check_length('len(a)','len(a)')
    call check_length('-n**2','-n**2')
    call check_length('2+n','2+n')
    call check_length('+n','+n')
    print '(a)','PASS: CHARACTER producer expressions, function results and length tokens'
contains
    subroutine check(expr,ok)
        character(*),intent(in)::expr
        logical,intent(in)::ok
        call compile_frontend_from_string('program p'//nl//'implicit none'//nl// &
            'character(2)::a(2)'//nl//'call take('//expr//')'//nl//'contains'//nl// &
            'subroutine take(x)'//nl//'character(*),intent(in)::x(:)'//nl// &
            'end subroutine'//nl//'function joined(x,y) result(z)'//nl// &
            'character(*),intent(in)::x(:),y(:)'//nl// &
            'character(max(len(x),len(y)))::z(size(x)+size(y))'//nl// &
            'z(:size(x))=x'//nl//'z(size(x)+1:)=y'//nl// &
            'end function'//nl//'end program',front,opts)
        if(front%success().neqv.ok) then
            print *,expr
            if(allocated(front%error_msg)) print *,front%error_msg
            error stop 'unexpected CHARACTER producer acceptance'
        end if
        if(.not.ok) return
        found=0
        do i=1,front%arena%entry_count
            if(.not.front%arena%has_node_at(i)) cycle
            select type(node=>front%arena%entries(i)%node)
            type is(subroutine_call_node)
                if(node%name/='take') cycle
                typ=query_resolved_type(front%arena,node%arg_indices(1))
                if(.not.typ%found.or.typ%rank/=1.or.typ%type_kind/=TCHAR.or. &
                   typ%kind_value/=1) error stop 'wrong CHARACTER expression metadata'
                found=found+1
            end select
        end do
        if(found/=1) error stop 'missing CHARACTER expression metadata'
    end subroutine
    subroutine check_length(expr,want)
        character(*),intent(in)::expr,want
        character(:),allocatable::compact
        integer::j
        call compile_frontend_from_string('subroutine p(a,n)'//nl// &
            'character(*),intent(in)::a'//nl//'integer,intent(in)::n'//nl// &
            'character('//expr//')::z'//nl//'end subroutine',front,opts)
        if(.not.front%success()) then
            if(allocated(front%error_msg)) print *,front%error_msg
            error stop 'CHARACTER length expression rejected'
        end if
        found=0
        do i=1,front%arena%entry_count
            if(.not.front%arena%has_node_at(i)) cycle
            select type(node=>front%arena%entries(i)%node)
            type is(declaration_node)
                if(.not.allocated(node%var_name)) cycle
                if(node%var_name/='z') cycle
                if(.not.allocated(node%character_length_expr)) error stop 'missing length tokens'
                compact=''
                do j=1,len(node%character_length_expr)
                    if(node%character_length_expr(j:j)/=' ') &
                        compact=compact//node%character_length_expr(j:j)
                end do
                if(compact/=want) then
                    print *,expr,compact,want
                    error stop 'CHARACTER length tokens changed'
                end if
                found=found+1
            end select
        end do
        if(found/=1) error stop 'missing CHARACTER length declaration'
    end subroutine
end program
