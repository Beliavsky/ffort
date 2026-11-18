! SPDX-License-Identifier: MIT
! Patch 0013 must preserve a complete AST, not merely compiler success.
program test_constructor_producer
    use fortfront_compiler
    use fortfront_ast, only: binary_op_node
    implicit none
    character(*),parameter::nl=new_line('a')
    type(compiler_frontend_options_t)::opts
    type(compiler_frontend_result_t)::front
    integer::i
    opts%input_mode=INPUT_MODE_STANDARD
    opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.
    opts%run_semantics=.true.
    call check('[1,[2,3],(/4,5/)]')
    call check('(/1,(/2,3/),4,5/)')
    call check('[(/1,2,3,4,5/)]')
    call check('(/(/1,2,3,4,5/)/)')
    call check('[(1+2),2,3,4,5]')
    print '(a)','PASS: nested constructor producer retains complete binary AST nodes'
contains
    subroutine check(expression)
        character(*),intent(in)::expression
        call compile_frontend_from_string('program p'//nl//'integer::a(5)'//nl// &
            'a='//expression//nl//'print *,a'//nl//'end program',front,opts)
        if(.not.front%success()) then
            if(allocated(front%error_msg)) print *,front%error_msg
            error stop 'nested constructor frontend failure'
        end if
        do i=1,front%arena%entry_count
            if(.not.front%arena%has_node_at(i)) cycle
            select type(node=>front%arena%entries(i)%node)
            type is(binary_op_node)
                if(.not.front%arena%has_node_at(node%left_index).or. &
                   .not.front%arena%has_node_at(node%right_index)) &
                    error stop 'nested constructor produced incomplete binary node'
            end select
        end do
    end subroutine
end program
