! SPDX-License-Identifier: MIT
program test_substring_producer
    use fortfront_compiler
    use fortfront_ast, only: subroutine_call_node, declaration_node
    use type_system_unified, only: TCHAR
    implicit none
    type(compiler_frontend_options_t)::opts
    type(compiler_frontend_result_t)::front
    type(resolved_type_query_t)::typ
    character(*),parameter::nl=new_line('a')
    integer::j,n,k
    opts%input_mode=INPUT_MODE_STANDARD
    opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.
    opts%run_semantics=.true.
    call check_call('s(1:2)','',0,.true.)
    call check_call('s(:)','',0,.true.)
    call check_call('s(1:2)','(:)',1,.false.)
    call check_call('a(1:2)','(:)',1,.true.)
    call check_call('a(1:2)','',0,.false.)
    call compile_frontend_from_string('module m'//nl//'implicit none'//nl// &
        'character(5)::a,b'//nl//'character(len=3)::c'//nl//'end module'//nl// &
        'program p'//nl//'end program',front,opts)
    if(.not.front%success()) error stop 'grouped CHARACTER producer rejected source'
    n=0
    do j=1,front%arena%entry_count
        if(.not.front%arena%has_node_at(j)) cycle
        select type(node=>front%arena%entries(j)%node)
        type is(declaration_node)
            if(.not.allocated(node%type_name)) cycle
            if(index(node%type_name,'character')/=1) cycle
            if(.not.node%has_character_length.or..not.allocated(node%character_length_expr)) &
                error stop 'grouped CHARACTER lost length metadata'
            if(node%character_length_expr/='5'.and.node%character_length_expr/='3') &
                error stop 'grouped CHARACTER changed length tokens'
            n=n+1
        end select
    end do
    if(n<2) error stop 'grouped CHARACTER declarations missing'
    print '(a)','PASS: substring producer rank and grouped CHARACTER length metadata'
contains
    subroutine check_call(actual,shape,rank,ok)
        character(*),intent(in)::actual,shape
        integer,intent(in)::rank
        logical,intent(in)::ok
        call compile_frontend_from_string('program p'//nl//'implicit none'//nl// &
            'character(3)::s'//nl//'character(3)::a(2)'//nl// &
            'call take('//actual//')'//nl//'contains'//nl// &
            'subroutine take(x)'//nl//'character(*),intent(in)::x'//shape//nl// &
            'end subroutine'//nl//'end program',front,opts)
        if(front%success().neqv.ok) then
            if(allocated(front%error_msg)) print *,front%error_msg
            error stop 'unexpected substring producer acceptance'
        end if
        if(.not.ok) return
        k=0
        do j=1,front%arena%entry_count
            if(.not.front%arena%has_node_at(j)) cycle
            select type(node=>front%arena%entries(j)%node)
            type is(subroutine_call_node)
                if(node%name/='take') cycle
                typ=query_resolved_type(front%arena,node%arg_indices(1))
                if(.not.typ%found.or.typ%rank/=rank.or.typ%type_kind/=TCHAR.or.typ%kind_value/=1) &
                    error stop 'wrong substring producer type or rank'
                k=k+1
            end select
        end do
        if(k/=1) error stop 'missing substring CALL'
    end subroutine
end program
