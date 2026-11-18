! SPDX-License-Identifier: MIT
program test_array_result_producer
    use fortfront_compiler
    use fortfront_ast,only:function_def_node
    implicit none
    character(*),parameter::nl=new_line('a')
    type(compiler_frontend_options_t)::opts
    type(compiler_frontend_result_t)::front
    integer::i,found
    opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.
    opts%run_semantics=.false.
    opts%input_mode=INPUT_MODE_STANDARD
    call check('',.false.)
    opts%input_mode=INPUT_MODE_LAZY
    call check('',.true.)
    opts%input_mode=INPUT_MODE_STANDARD
    call check('',.false.)
    call check('recursive ',.true.)
    print '(a)','PASS: array-result producer written prefixes and STANDARD/LAZY mode isolation'
contains
    subroutine check(prefix,recursive_expected)
        character(*),intent(in)::prefix
        logical,intent(in)::recursive_expected
        call compile_frontend_from_string('program p'//nl//'implicit none'//nl// &
            'print *,f(2)'//nl//'contains'//nl//prefix//'function f(n)'//nl// &
            'integer,intent(in)::n'//nl//'integer::f(n),i'//nl// &
            'do i=1,n'//nl//'f(i)=i'//nl//'end do'//nl//'end function'//nl//'end program',front,opts)
        if(.not.front%success()) then
            if(allocated(front%error_msg)) print *,front%error_msg
            error stop 'array-result producer failure'
        end if
        found=0
        do i=1,front%arena%entry_count
            if(.not.front%arena%has_node_at(i)) cycle
            select type(node=>front%arena%entries(i)%node)
            type is(function_def_node)
                if(node%name/='f')cycle
                found=found+1
                if(node%is_recursive.neqv.recursive_expected) error stop 'array-result recursion metadata differs'
                if(allocated(node%prefix_keywords)) then
                    if(any(node%prefix_keywords=='recursive').neqv.recursive_expected) &
                        error stop 'array-result written prefix differs'
                else if(recursive_expected) then
                    error stop 'array-result explicit prefix missing'
                end if
            end select
        end do
        if(found/=1) error stop 'array-result function missing'
    end subroutine
end program
