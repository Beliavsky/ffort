! SPDX-License-Identifier: MIT
program test_optional_arguments
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='module m'//nl//'implicit none'//nl//'contains'//nl// &
        'pure function choose(a,b) result(x)'//nl//'integer,intent(in)::a'//nl// &
        'integer,optional,intent(in)::b'//nl//'integer::x'//nl//'x=a'//nl// &
        'if(present(b)) x=b'//nl//'end function'//nl//'end module'//nl// &
        'program main'//nl//'use m'//nl//'implicit none'//nl//'integer::x'//nl// &
        'x=choose(a=3)'//nl//'if(x/=3) error stop 1'//nl//'end program'
    integer::which,j,call_expr,present_expr,dummy,checks
    checks=0
    do which=1,10
        call fixture()
        select case(which)
        case(2);p%symbols(dummy)%is_optional=.false.
        case(3);p%symbols(dummy)%is_dummy=.false.
        case(4);p%expressions(call_expr)%args=p%expressions(call_expr)%args(:1)
        case(5);p%expressions(call_expr)%args(1)=0
        case(6);p%expressions(call_expr)%args=p%expressions(call_expr)%args([2,1])
        case(7);p%expressions(present_expr)%typ=ty_integer
        case(8);p%expressions(present_expr)%real_kind=8
        case(9);p%expressions(present_expr)%args(1)=0
        case(10);p%expressions(p%expressions(present_expr)%args(1))%parenthesized=.true.
        end select
        call verify_frontend(source,p,d)
        call expect((d%code==0).eqv.(which==1),'OPTIONAL/PRESENT adapter mutation')
    end do
    do which=1,15
        call fixture()
        select case(which)
        case(2);p%symbols(dummy)%is_optional=.false.
        case(3);p%expressions(call_expr)%args(1)=0
        case(4);p%expressions(call_expr)%args(2)=-1
        case(5);p%expressions(call_expr)%args(2)=p%ne+1
        case(6);p%expressions(present_expr)%typ=ty_integer
        case(7);p%expressions(present_expr)%real_kind=8
        case(8);p%expressions(present_expr)%args(1)=0
        case(9);p%expressions(present_expr)%args(1)=p%ne+1
        case(10);p%expressions(present_expr)%args=[integer::]
        case(11);p%expressions(p%expressions(present_expr)%args(1))%parenthesized=.true.
        case(12);p%expressions(p%expressions(present_expr)%args(1))%symbol=p%ns+1
        case(13);p%symbols(dummy)%rank=1
        case(14);p%symbols(dummy)%typ=ty_derived_base
        case(15);p%symbols(dummy)%is_dummy=.false.
        end select
        call execute_program(p,d)
        call expect((d%code==0).eqv.(which==1),'OPTIONAL/PRESENT runtime mutation')
    end do
    print *, 'PASS: OPTIONAL/PRESENT mutation checks:',checks
contains
    subroutine fixture()
        call parse_subset(source,p,d)
        if(d%code/=0) then
            print *,d%message
            error stop 'optional fixture parse'
        end if
        call_expr=0;present_expr=0
        do j=1,p%ne
            if(p%expressions(j)%kind==ex_user_call) call_expr=j
            if(p%expressions(j)%op=='present') present_expr=j
        end do
        if(call_expr==0.or.present_expr==0) error stop 'optional fixture IR'
        dummy=p%procedures(1)%args(2)
    end subroutine
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok)return
        print *, 'FAIL: ',label,' mutation=',which
        if(allocated(d%message))print *,d%message
        error stop 1
    end subroutine
end program
