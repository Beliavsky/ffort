! SPDX-License-Identifier: MIT
! Direct FortFront producer check: retain SIMPLE, do not rewrite it as PURE.
program test_pure_simple_producers
    use fortfront_compiler
    use ast_nodes_procedure, only: function_def_node, subroutine_def_node
    implicit none
    character(*),parameter::nl=new_line('a')
    type(compiler_frontend_options_t)::opts
    type(compiler_frontend_result_t)::front
    integer::i,n,j
    opts%input_mode=INPUT_MODE_STANDARD
    opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.;opts%run_semantics=.true.
    call compile_frontend_from_string('module m'//nl//'implicit none'//nl//'contains'//nl// &
        'simple integer function f(x) result(r)'//nl//'integer,intent(in)::x'//nl// &
        'r=x+1'//nl//'end function'//nl// &
        'integer simple function g(x) result(r)'//nl//'integer,intent(in)::x'//nl// &
        'r=f(x)'//nl//'end function'//nl// &
        'simple subroutine s(x)'//nl//'integer,intent(inout)::x'//nl// &
        'x=g(x)'//nl//'end subroutine'//nl//'end module'//nl// &
        'program p'//nl//'use m'//nl//'implicit none'//nl//'integer::x'//nl// &
        'x=1'//nl//'call s(x)'//nl//'print *,h(x)'//nl//'contains'//nl// &
        'integer simple function h(x) result(r)'//nl//'integer,intent(in)::x'//nl// &
        'r=x+1'//nl//'end function'//nl//'end program',front,opts)
    if(.not.front%success()) then
        if(allocated(front%error_msg)) print *,front%error_msg
        error stop 'producer rejected SIMPLE'
    end if
    n=0
    do i=1,front%arena%entry_count
        if(.not.front%arena%has_node_at(i)) cycle
        select type(node=>front%arena%entries(i)%node)
        type is(function_def_node)
            call check_prefix(node%prefix_keywords);n=n+1
        type is(subroutine_def_node)
            call check_prefix(node%prefix_keywords);n=n+1
        end select
    end do
    if(n/=4) error stop 'SIMPLE producer procedure count differs'
    ! SIMPLE activates existing pure-body checks in the producer too.
    call compile_frontend_from_string('program p'//nl//'contains'//nl// &
        'simple subroutine s()'//nl//'print *,1'//nl//'end subroutine'//nl//'end program',front,opts)
    if(front%success()) error stop 'producer accepted output in SIMPLE subroutine'
    print '(a)','PASS: producer preserves SIMPLE prefixes and rejects SIMPLE output'
contains
    subroutine check_prefix(prefix)
        character(16),allocatable,intent(in)::prefix(:)
        if(.not.allocated(prefix)) error stop 'SIMPLE prefix absent'
        if(size(prefix)/=1) error stop 'SIMPLE prefix count differs'
        if(trim(prefix(1))/='simple') error stop 'SIMPLE prefix rewritten/lost'
    end subroutine
end program
