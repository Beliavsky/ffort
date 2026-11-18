! SPDX-License-Identifier: MIT
program test_elemental_mutable_runtime
    use, intrinsic :: iso_fortran_env, only: int64
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_runtime, only: execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::header='program p'//nl//'integer::a(4),b(4),empty(0),unused'//nl//'real::bad(4)'//nl
    character(*),parameter::bodies='contains'//nl// &
        'elemental subroutine change(x,y)'//nl//'integer,intent(in)::x'//nl// &
        'integer,intent(out)::y'//nl//'y=x+1'//nl//'end subroutine'//nl// &
        'impure elemental integer function f(x) result(r)'//nl//'integer,intent(in)::x'//nl// &
        'r=x*2'//nl//'end function'//nl//'end program'
    character(:),allocatable::source
    integer::which,j,c,e
    source=header//'a=2'//nl//'call change(a,b)'//nl//'a=f(b)'//nl// &
        'if(sum(a)/=24) error stop 1'//nl//'call change(unused,empty)'//nl//bodies
    do which=1,9
        call parse_subset(source,p,d)
        call okay('parse')
        c=0
        do j=1,p%nc
            if(p%code(j)%op==op_call) then
                c=j;exit
            end if
        end do
        e=p%code(c)%items(2)
        select case(which)
        case(2);p%procedures(1)%is_elemental=.false.
        case(3);p%procedures(1)%is_pure=.false.
        case(4);p%procedures(2)%has_impure_prefix=.false.
        case(5);p%code(c)%items(2)=p%code(c)%items(1)
        case(6);p%symbols(p%procedures(1)%args(2))%rank=1
        case(8);p%symbols(p%procedures(1)%args(1))%dummy_intent=0
        case(9)
            do j=1,p%ns
                if(p%symbols(j)%name=='bad') p%expressions(e)%symbol=j
            end do
        end select
        if(which==7) then
            call execute_program(p,d,max_steps=15_int64)
        else
            call execute_program(p,d)
        end if
        if(which==1) then
            call okay('runtime')
        else if(d%code==0) then
            print *,which
            error stop 'mutable ELEMENTAL invalid runtime admitted'
        end if
    end do
    call parse_subset(header//'a=1'//nl//'call change(a(1:3),a(2:4))'//nl//bodies,p,d)
    call okay('overlap parse')
    call execute_program(p,d)
    if(d%code==0) error stop 'cross-element overlap admitted'
    if(index(d%message,'overlapping')==0) error stop 'wrong cross-element diagnostic'
    source='program p'//nl//'integer::a(2)'//nl//'a=7'//nl//'call erase(a)'//nl// &
        'print *,a'//nl//'contains'//nl//'elemental subroutine erase(x)'//nl// &
        'integer,intent(out)::x'//nl//'end subroutine'//nl//'end program'
    call parse_subset(source,p,d)
    call okay('OUT parse')
    call execute_program(p,d)
    if(d%code==0) error stop 'OUT old definition resurrected'
    if(index(d%message,'uninitialized')==0) error stop 'wrong OUT diagnostic'
    call parse_subset(header//'call change(unused,empty)'//nl//bodies,p,d)
    call okay('empty malformed parse')
    p%symbols(p%procedures(1)%args(1))%dummy_intent=0
    call execute_program(p,d)
    if(d%code==0) error stop 'empty elemental call admitted malformed dummy intent'
    print '(a)','PASS: mutable ELEMENTAL values, empty calls, shared budget, aliases and OUT flags'
contains
    subroutine okay(label)
        character(*),intent(in)::label
        if(d%code==0) return
        print *,label,d%message
        error stop 'mutable ELEMENTAL runtime baseline failed'
    end subroutine
end program
