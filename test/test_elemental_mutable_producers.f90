! SPDX-License-Identifier: MIT
! Producer regression: both strict CALL paths must pass the ELEMENTAL flag.
program test_elemental_mutable_producers
    use fortfront_compiler
    use ast_nodes_procedure, only: subroutine_def_node
    implicit none
    character(*),parameter::nl=new_line('a')
    type(compiler_frontend_options_t)::opts
    type(compiler_frontend_result_t)::front
    integer::i,elementals,impures
    opts%input_mode=INPUT_MODE_STANDARD
    opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.
    opts%run_semantics=.true.
    call compile_frontend_from_string('module m'//nl//'contains'//nl// &
        'elemental subroutine change(x)'//nl//'integer,intent(inout)::x'//nl// &
        'x=x+1'//nl//'end subroutine'//nl//'end module'//nl// &
        'program p'//nl//'use m'//nl//'integer::a(2,3)'//nl//'a=1'//nl// &
        'call change(a)'//nl//'call change(a(:,2))'//nl//'call show(a)'//nl// &
        'contains'//nl//'impure elemental subroutine show(x)'//nl// &
        'integer,intent(inout)::x'//nl//'print *,x'//nl//'end subroutine'//nl// &
        'end program',front,opts)
    if(.not.front%success()) then
        if(allocated(front%error_msg)) print *,front%error_msg
        error stop 'producer rejects conformable elemental subroutine array calls'
    end if
    elementals=0;impures=0
    do i=1,front%arena%entry_count
        if(.not.front%arena%has_node_at(i)) cycle
        select type(node=>front%arena%entries(i)%node)
        type is(subroutine_def_node)
            if(.not.allocated(node%prefix_keywords)) error stop 'producer lost prefixes'
            if(any(node%prefix_keywords=='elemental')) elementals=elementals+1
            if(any(node%prefix_keywords=='impure')) impures=impures+1
        end select
    end do
    if(elementals/=2.or.impures/=1) error stop 'producer changed elemental/impure designations'
    call compile_frontend_from_string('program p'//nl//'real::a(3)'//nl//'a=1.0'//nl// &
        'call change(a)'//nl//'contains'//nl//'elemental subroutine change(x)'//nl// &
        'integer,intent(inout)::x'//nl//'x=x+1'//nl//'end subroutine'//nl//'end program',front,opts)
    if(front%success()) error stop 'producer bypassed elemental argument element type check'
    print '(a)','PASS: ELEMENTAL CALL producer rank lifting, prefix retention and element type rejection'
end program
