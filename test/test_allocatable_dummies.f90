! SPDX-License-Identifier: MIT
program test_allocatable_dummies
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: execute_program
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='module m'//nl//'contains'//nl// &
        'subroutine make(a)'//nl//'integer,allocatable,intent(out)::a(:)'//nl// &
        'if(allocated(a)) error stop 1'//nl//'allocate(a(-2:0))'//nl//'a=4'//nl//'end subroutine'//nl// &
        'subroutine grow(a)'//nl//'integer,allocatable,intent(inout)::a(:)'//nl// &
        'a=[a,8]'//nl//'end subroutine'//nl// &
        'end module'//nl//'program main'//nl//'use m'//nl//'integer,allocatable::v(:)'//nl// &
        'call make(v)'//nl//'call grow(v)'//nl// &
        'if(size(v)/=4.or.sum(v)/=20.or.lbound(v,1)/=1) error stop 2'//nl//'end program'
    type(program_t)::p
    type(diagnostic_t)::d
    integer::i,j,actual,actual_symbol,dummy,callpc
    call fresh()
    call verify_frontend(source,p,d)
    if(d%code/=0) then
        print *,d%message
        error stop 'allocatable dummy baseline frontend'
    end if
    do i=1,3
        call execute_program(p,d)
        if(d%code/=0) then
            print *,d%message
            error stop 'allocatable dummy reset baseline'
        end if
    end do
    do i=1,5
        call fresh()
        callpc=0
        do j=1,p%nc
            if(p%code(j)%op==op_call) then
                callpc=j;exit
            end if
        end do
        actual=p%code(callpc)%items(1);actual_symbol=p%expressions(actual)%symbol
        dummy=p%procedures(p%code(callpc)%symbol)%args(1)
        select case(i)
        case(1)
            p%symbols(actual_symbol)%is_allocatable=.false.
        case(2)
            p%expressions(actual)%parenthesized=.true.
        case(3)
            p%symbols(dummy)%dummy_intent=1
        case(4)
            p%symbols(dummy)%is_allocatable=.false.
        case(5)
            p%symbols(dummy)%rank=2
        end select
        call verify_frontend(source,p,d)
        if(d%code/=1) error stop 'allocatable dummy adapter mutation escaped'
        d=diagnostic_t()
        call execute_program(p,d)
        if(d%code/=2) then
            print *,i,d%code
            error stop 'allocatable dummy runtime mutation escaped'
        end if
    end do
    print '(a)','PASS: allocatable dummy repeated runs and 10 adapter/runtime mutation rejections'
contains
    subroutine fresh()
        d=diagnostic_t()
        call parse_subset(source,p,d)
        if(d%code/=0) error stop 'allocatable dummy baseline parse'
    end subroutine
end program
