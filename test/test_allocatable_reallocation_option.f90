! SPDX-License-Identifier: MIT
program test_allocatable_reallocation_option
    use fortfront_compiler, only: compiler_frontend_options_t, compiler_frontend_result_t, &
        compile_frontend_from_string, INPUT_MODE_STANDARD, OPERATING_MODE_STRICT
    implicit none
    type(compiler_frontend_options_t)::opts
    type(compiler_frontend_result_t)::front
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program main'//nl//'implicit none'//nl// &
        'integer,allocatable::a(:)'//nl//'a=[1,2,3]'//nl//'a=[4,5]'//nl//'end program'
    character(*),parameter::bad_source='program main'//nl//'implicit none'//nl// &
        'integer,allocatable::a(:)'//nl//'a=[1,2,3]'//nl//'a=[4,5]'//nl// &
        'not_declared=1'//nl//'end program'
    opts%input_mode=INPUT_MODE_STANDARD
    opts%operating_mode=OPERATING_MODE_STRICT
    call compile_frontend_from_string(source,front,opts)
    if(front%success()) error stop 'default strict allocation policy changed'
    if(.not.allocated(front%error_msg)) error stop 'missing strict allocation diagnostic'
    if(index(front%error_msg,'reallocation')==0) error stop 'wrong strict allocation diagnostic'
    opts%allow_allocatable_reallocation=.true.
    call compile_frontend_from_string(source,front,opts)
    if(.not.front%success()) then
        if(allocated(front%error_msg)) print *,front%error_msg
        error stop 'explicit reallocation option failed'
    end if
    call compile_frontend_from_string(bad_source,front,opts)
    if(front%success()) error stop 'reallocation option bypassed implicit none'
    if(.not.allocated(front%error_msg)) error stop 'missing undeclared variable diagnostic'
    print *, 'PASS: allocatable reallocation opt-in preserves strict defaults'
end program
