! SPDX-License-Identifier: MIT
program test_selected_real_kind
    use, intrinsic :: iso_fortran_env, only: int64
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:evaluate_constant
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    type(value_t)::v
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        'print *,selected_real_kind(r=307,p=15,radix=2)'//nl//'end program'
    character(*),parameter::inquiry_source='program p'//nl//'implicit none'//nl// &
        'integer::undefined'//nl//'print *,kind(selected_real_kind(undefined))'//nl//'end program'
    integer::which,j,e,checks
    checks=0
    do which=1,7
        call parse_subset(source,p,d)
        if(d%code/=0) error stop 'guard rejected selected real kind'
        e=0
        do j=1,p%ne
            if(p%expressions(j)%op=='selected_real_kind')e=j
        end do
        if(e==0)error stop 'selected real kind missing'
        select case(which)
        case(2);p%expressions(e)%intrinsic_mask=3
        case(3);p%expressions(e)%real_kind=8
        case(4);p%expressions(e)%args=p%expressions(e)%args([2,1,3])
        case(5);p%expressions(e)%rank=1;p%expressions(e)%extent=1
        case(6);p%expressions(e)%typ=ty_real
        case(7);p%expressions(e)%intrinsic_mask=8
        end select
        call verify_frontend(source,p,d)
        call expect((d%code==0).eqv.(which==1),'adapter mutation')
    end do
    call value_case([6_int64,37_int64],3,4_int64)
    call value_case([15_int64,307_int64],3,8_int64)
    call value_case([16_int64],1,-1_int64)
    call value_case([308_int64],2,-2_int64)
    call value_case([16_int64,308_int64],3,-3_int64)
    call value_case([10_int64],4,-5_int64)
    call value_case([integer(int64)::],0,4_int64)
    do which=1,17
        call runtime_fixture([6_int64,37_int64],3)
        select case(which)
        case(1);p%expressions(3)%intrinsic_mask=1
        case(2);p%expressions(3)%intrinsic_mask=8
        case(3);p%expressions(3)%typ=ty_real
        case(4);p%expressions(3)%real_kind=8
        case(5);p%expressions(3)%rank=1;p%expressions(3)%extent=1
        case(6);p%expressions(1)%typ=ty_real;p%expressions(1)%value%tag=ty_real
        case(7);p%expressions(1)%rank=1;p%expressions(1)%extent=1
        case(8);p%expressions(1)%typ=ty_real
        case(9);p%expressions(1)%real_kind=16
        case(10);p%expressions(1)%real_kind=8
        case(11);p%expressions(1)%value%real_kind=8
        case(12);p%expressions(3)%args(1)=0
        case(13);p%expressions(3)%args(1)=p%ne+1
        case(14);p%expressions(3)%args(1)=-1
        case(15);deallocate(p%expressions(3)%args)
        case(16);p%expressions(3)%intrinsic_mask=-1
        case(17);p%expressions(3)%args(1)=3
        end select
        call evaluate_constant(p,3,v,d)
        call expect(d%code/=0,'runtime mutation')
    end do
    call runtime_fixture([6_int64,37_int64],3)
    p%expressions(1)%real_kind=8;p%expressions(1)%value%real_kind=8
    call evaluate_constant(p,3,v,d)
    call expect(d%code==0,'valid INTEGER(8) argument')
    call expect(v%i==4.and.v%real_kind==4,'default INTEGER result from INTEGER(8) argument')
    call parse_subset(inquiry_source,p,d)
    call expect(d%code==0,'KIND inquiry fixture')
    e=0
    do j=1,p%ne
        if(p%expressions(j)%op=='kind')e=j
    end do
    if(e==0)error stop 'KIND inquiry missing'
    call evaluate_constant(p,e,v,d)
    call expect(d%code==0,'KIND does not evaluate undefined SRK argument')
    call expect(v%i==4,'KIND inquiry result')
    print *, 'PASS: SELECTED_REAL_KIND adapter/runtime checks:',checks
contains
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok)return
        print *, 'FAIL: ',label
        if(allocated(d%message))print *,d%message
        error stop 1
    end subroutine
    subroutine value_case(values,mask,expected)
        integer(int64),intent(in)::values(:),expected
        integer,intent(in)::mask
        call runtime_fixture(values,mask)
        call evaluate_constant(p,size(values)+1,v,d)
        call expect(d%code==0,'runtime value diagnostic')
        call expect(v%i==expected.and.v%tag==ty_integer.and.v%real_kind==4,'runtime value')
    end subroutine
    subroutine runtime_fixture(values,mask)
        integer(int64),intent(in)::values(:)
        integer,intent(in)::mask
        integer::j,n
        p=program_t();d=diagnostic_t();n=size(values)
        allocate(p%symbols(0),p%expressions(n+1),p%code(0));p%ne=n+1
        do j=1,n
            p%expressions(j)=expr_t(kind=ex_literal,typ=ty_integer, &
                value=value_t(tag=ty_integer,i=values(j)))
        end do
        p%expressions(n+1)=expr_t(kind=ex_call,typ=ty_integer,op='selected_real_kind', &
            args=[(j,j=1,n)],intrinsic_mask=mask)
    end subroutine
end program
