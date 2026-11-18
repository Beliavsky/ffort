! SPDX-License-Identifier: MIT
program test_derived_runtime
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_runtime, only: execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::prefix='module records'//nl//'type :: pair'//nl// &
        'integer :: first,second'//nl//'end type'//nl//'end module'//nl// &
        'program main'//nl//'use records'//nl//'type(pair)::p,q'//nl
    character(:),allocatable::source
    integer::which,a,j
    do which=1,10
        source=prefix//'p=pair(2,3)'//nl//'q=p'//nl//'p%first=8'//nl// &
            'if(q%first/=2.or.q%second/=3.or.p%first/=8) error stop 1'//nl//'end program'
        if(which==2) source=prefix//'p%first=2'//nl//'q=p'//nl//'end program'
        if(which==3) source=prefix//'q%first=p%first'//nl//'end program'
        if(which==4) source=prefix//'p%first=2'//nl//'q%first=p%first'//nl//'end program'
        if(which==8) source='program main'//nl//'stop'//nl//'error stop 1'//nl//'end program'
        if(which==9) source='program main'//nl//"stop 'done'"//nl//'error stop 1'//nl//'end program'
        if(which==10) source='program main'//nl//'stop 7'//nl//'error stop 1'//nl//'end program'
        call parse_subset(source,p,d)
        if(d%code/=0) then
            print *,which,d%message
            error stop 'derived runtime fixture parse failed'
        end if
        select case(which)
        case(5)
            p%code(3)%component=17
        case(6)
            a=p%code(1)%a
            p%expressions(a)%args=p%expressions(a)%args(:1)
        case(7)
            do j=1,p%ne
                if(p%expressions(j)%kind/=ex_component) cycle
                p%expressions(j)%symbol=0;exit
            end do
        end select
        call execute_program(p,d)
        select case(which)
        case(1,4)
            if(d%code/=0) then
                print *,which,d%message
                error stop 'derived runtime baseline failed'
            end if
        case(8:10)
            if(d%code/=3) error stop 'STOP did not unwind normally'
            if(which==10.and.d%stop_status/=7) error stop 'STOP code was lost'
            if(which/=10.and.d%stop_status/=0) error stop 'STOP default status differs'
        case default
            if(d%code/=2) error stop 'invalid or undefined derived access was accepted'
        end select
    end do
    print '(a)','PASS: 10 derived runtime, definition-state and normal STOP contracts'
end program
