! SPDX-License-Identifier: MIT
program test_selected_real_kind_empty_selector
    use fortfront_compiler
    use fortfront_ast,only:declaration_node
    implicit none
    type(compiler_frontend_options_t)::opts
    type(compiler_frontend_result_t)::front
    type(resolved_type_query_t)::typ
    character(*),parameter::nl=new_line('a')
    integer::i,found
    opts%input_mode=INPUT_MODE_STANDARD
    opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.
    opts%run_semantics=.true.
    call check('selected_real_kind()',.true.)
    call check('kind=selected_real_kind()',.true.)
    call check('kind=SELECTED_REAL_KIND()',.true.)
    call check('kind=kind()',.false.)
    call check('kind=selected_int_kind()',.false.)
    call check('kind=unknown()',.false.)
    print '(a)','PASS: three empty SELECTED_REAL_KIND selectors and three invalid empty calls'
contains
    subroutine check(selector,valid)
        character(*),intent(in)::selector
        logical,intent(in)::valid
        call compile_frontend_from_string('program p'//nl//'implicit none'//nl// &
            'real('//selector//')::answer'//nl//'end program',front,opts)
        if(front%success().neqv.valid) then
            if(allocated(front%error_msg))print *,front%error_msg
            error stop 'empty kind selector acceptance mismatch'
        end if
        if(.not.valid)return
        found=0
        do i=1,front%arena%entry_count
            if(.not.front%arena%has_node_at(i))cycle
            select type(node=>front%arena%entries(i)%node)
            type is(declaration_node)
                if(node%var_name/='answer')cycle
                found=found+1
                typ=query_resolved_type(front%arena,i)
                if(.not.typ%found.or.typ%type_kind/=TREAL.or.typ%kind_value/=4.or.typ%rank/=0) &
                    error stop 'empty selected real kind metadata differs'
            end select
        end do
        if(found/=1)error stop 'empty selected real kind declaration missing'
    end subroutine
end program
