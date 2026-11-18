! SPDX-License-Identifier: MIT
program test_kind_inquiry_producer
    use fortfront_compiler
    use fortfront_ast, only: declaration_node
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
    call check('', 'kind=kind(1d0)')
    call check('', 'kind=kind([1d0,2d0])')
    call check('', 'kind(x=1d0)')
    call check('integer,parameter::working=kind(1d0)'//nl, 'working')
    call check('real(8)::z'//nl//'integer,parameter::working=kind(z)'//nl, 'working')
    call check('real(8)::z(2)'//nl, 'kind=kind(x=z)')
    call check_call('1d0',.true.)
    call check_call('1.0',.false.)
    print '(a)','PASS: KIND type-inquiry producer resolves direct and named REAL selectors'
contains
    subroutine check_call(actual,expected)
        character(*),intent(in)::actual
        logical,intent(in)::expected
        call compile_frontend_from_string('program p'//nl// &
            'print *,identity('//actual//')'//nl//'contains'//nl// &
            'function identity(x) result(y)'//nl// &
            'real(kind=kind(1d0)),intent(in)::x'//nl// &
            'real(kind=kind(1d0))::y'//nl//'y=x'//nl// &
            'end function'//nl//'end program',front,opts)
        if(front%success().neqv.expected) then
            if(allocated(front%error_msg)) print *,front%error_msg
            error stop 'KIND strict dummy type mismatch'
        end if
    end subroutine
    subroutine check(declarations,selector)
        character(*),intent(in)::declarations,selector
        call compile_frontend_from_string('program p'//nl//'implicit none'//nl// &
            declarations//'real('//selector//')::answer'//nl//'end program',front,opts)
        if(.not.front%success()) then
            if(allocated(front%error_msg)) print *,front%error_msg
            error stop 'KIND selector frontend failure'
        end if
        found=0
        do i=1,front%arena%entry_count
            if(.not.front%arena%has_node_at(i)) cycle
            select type(node=>front%arena%entries(i)%node)
            type is(declaration_node)
                if(node%var_name/='answer') cycle
                found=found+1
                typ=query_resolved_type(front%arena,i)
                if(.not.typ%found.or.typ%type_kind/=TREAL.or.typ%kind_value/=8.or.typ%rank/=0) &
                    error stop 'KIND selector lost exact declaration type'
            end select
        end do
        if(found/=1) error stop 'KIND declaration missing'
    end subroutine
end program
