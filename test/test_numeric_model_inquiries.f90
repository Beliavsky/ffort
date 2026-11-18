! SPDX-License-Identifier: MIT
program test_numeric_model_inquiries
    use, intrinsic :: iso_fortran_env, only: int64, real32, real64
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: evaluate_constant, evaluate_constant_array
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    type(value_t)::v
    type(value_t),allocatable::array_values(:)
    character(*),parameter::nl=new_line('a')
    character(7),parameter::names(4)=[character(7)::'epsilon','radix','tiny','huge']
    character(:),allocatable::source
    integer::which,j,e,arg,op,checks,k,t
    checks=0
    do op=1,4
        source='program p'//nl//'implicit none'//nl//'real(8)::x(2,3)'//nl// &
            'print *,'//trim(names(op))//'(x=x)'//nl//'end program'
        do which=1,12
            call parse_subset(source,p,d)
            call expect(d%code==0,'parse model inquiry')
            e=find_call(trim(names(op)));arg=p%expressions(e)%args(1)
            select case(which)
            case(2);p%expressions(e)%typ=ty_logical
            case(3);p%expressions(e)%real_kind=16
            case(4);p%expressions(e)%rank=1;p%expressions(e)%extent=1
            case(5);p%expressions(e)%extent=-1
            case(6);p%expressions(e)%dims(1)=1
            case(7);p%expressions(e)%intrinsic_mask=1
            case(8);p%expressions(arg)%real_kind=4
            case(9);p%expressions(e)%args=[arg,arg]
            case(10);p%expressions(e)%args=[integer::]
            case(11);p%expressions(e)%op='sin'
            case(12);p%expressions(arg)%rank=1
            end select
            call verify_frontend(source,p,d)
            call expect((d%code==0).eqv.(which==1),'adapter mutation')
        end do
        do which=1,19
            call fixture(trim(names(op)),ty_real,8)
            select case(which)
            case(1);p%expressions(2)%typ=ty_logical
            case(2);p%expressions(2)%real_kind=16
            case(3);p%expressions(2)%rank=1;p%expressions(2)%extent=1
            case(4);p%expressions(2)%extent=-1
            case(5);p%expressions(2)%dims(1)=1
            case(6);p%expressions(2)%intrinsic_mask=1
            case(7);p%expressions(2)%args=[1,1]
            case(8);p%expressions(2)%args=[integer::]
            case(9);deallocate(p%expressions(2)%args)
            case(10);p%expressions(2)%args(1)=0
            case(11);p%expressions(2)%args(1)=3
            case(12);p%expressions(2)%args(1)=2
            case(13);p%expressions(1)%real_kind=16
            case(14);p%expressions(1)%rank=4
            case(15);p%expressions(1)%typ=ty_character
            case(16);p%expressions(1)%value%tag=ty_integer
            case(17);p%expressions(1)%value%real_kind=4
            case(18);p%expressions(1)%kind=ex_variable;p%expressions(1)%symbol=1
            case(19);p%expressions(2)%intrinsic_mask=-1
            end select
            call evaluate_constant(p,2,v,d)
            call expect(d%code/=0,'runtime mutation')
        end do
        do k=4,8,4
            call fixture(trim(names(op)),ty_real,k)
            call evaluate_constant(p,2,v,d)
            call expect(d%code==0,'REAL inquiry evaluates')
            if(op==2) then
                call expect(v%tag==ty_integer.and.v%real_kind==4.and.v%i==2,'RADIX value')
            else
                call expect(v%tag==ty_real.and.v%real_kind==k,'REAL result metadata')
                if(k==4) then
                    select case(op)
                    case(1);call expect(v%r==real(epsilon(0.0_real32),real64),'EPSILON32 value')
                    case(3);call expect(v%r==real(tiny(0.0_real32),real64),'TINY32 value')
                    case(4);call expect(v%r==real(huge(0.0_real32),real64),'HUGE32 value')
                    end select
                else
                    select case(op)
                    case(1);call expect(v%r==epsilon(0.0_real64),'EPSILON64 value')
                    case(3);call expect(v%r==tiny(0.0_real64),'TINY64 value')
                    case(4);call expect(v%r==huge(0.0_real64),'HUGE64 value')
                    end select
                end if
            end if
        end do
        source='program p'//nl//'implicit none'//nl//'real(8)::x(2)'//nl// &
            'print *,kind('//trim(names(op))//'(x))'//nl//'end program'
        call parse_subset(source,p,d)
        call expect(d%code==0,'nested KIND parse')
        e=find_call('kind')
        call evaluate_constant(p,e,v,d)
        call expect(d%code==0,'nested KIND does not read undefined array')
        call expect(v%i==merge(4,8,op==2),'nested KIND result')
    end do
    do k=4,8,4
        call fixture('huge',ty_integer,k)
        call evaluate_constant(p,2,v,d)
        call expect(d%code==0,'INTEGER HUGE evaluates')
        call expect(v%tag==ty_integer.and.v%real_kind==k,'INTEGER HUGE metadata')
        if(k==4) call expect(v%i==2147483647_int64,'INTEGER32 HUGE')
        if(k==8) call expect(v%i==huge(0_int64),'INTEGER64 HUGE')
    end do
    ! Nested metadata is checked even when a type inquiry suppresses value evaluation.
    call fixture('epsilon',ty_real,4)
    p%expressions(1)=expr_t(kind=ex_call,typ=ty_real,op='epsilon',args=[2])
    call evaluate_constant(p,2,v,d)
    call expect(d%code/=0,'nested model cycle')
    source='program p'//nl//'real::a(0),x'//nl//'a=a+epsilon(x)'//nl//'end program'
    call parse_subset(source,p,d)
    call expect(d%code==0,'empty enclosing expression parse')
    e=find_call('epsilon');p%expressions(e)%real_kind=16
    call evaluate_constant_array(p,p%code(1)%a,array_values,d)
    call expect(d%code/=0,'empty context model metadata mutation')
    ! A valid numeric component is still outside this bounded inquiry subset.
    ! Build coherent IR through ABS, then verify it independently against EPSILON
    ! source so the adapter rejection cannot rely on the parser guard.
    source='module types'//nl//'implicit none'//nl//'type :: item'//nl// &
        'real(8)::x'//nl//'end type'//nl//'end module'//nl//'program p'//nl// &
        'use types'//nl//'implicit none'//nl//'type(item)::a'//nl// &
        'print *,abs(a%x+1d0)'//nl//'end program'
    call parse_subset(source,p,d)
    call expect(d%code==0,'numeric component adapter fixture')
    e=find_call('abs');p%expressions(e)%op='epsilon'
    j=index(source,'abs(')
    source=source(:j-1)//'epsilon'//source(j+3:)
    call verify_frontend(source,p,d)
    call expect(d%code/=0,'adapter independently rejects nested component operand')
    d=diagnostic_t()
    call evaluate_constant(p,e,v,d)
    call expect(d%code/=0,'direct runtime retains component boundary')
    call parse_subset(source,p,d)
    call expect(d%code/=0,'parser rejects nested component operand')
    ! A shared DAG must be visited once, not exponentially expanded. Forty-eight
    ! repeated-child levels would require 2**48 visits without memoization.
    source='program p'//nl//'print *,epsilon(1d0)'//nl//'end program'
    call parse_subset(source,p,d)
    call expect(d%code==0,'shared DAG fixture')
    e=find_call('epsilon');arg=p%expressions(e)%args(1)
    do j=1,48
        p%ne=p%ne+1
        p%expressions(p%ne)=expr_t(kind=ex_binary,typ=ty_real,real_kind=8,op='+',left=arg,right=arg)
        arg=p%ne
    end do
    p%expressions(e)%args=[arg]
    call verify_frontend(source,p,d)
    call expect(d%code/=0,'shared DAG source mismatch rejects promptly')
    d=diagnostic_t()
    call evaluate_constant(p,e,v,d)
    call expect(d%code==0,'shared DAG inquiry runtime is metadata-only')
    p%expressions(arg)%left=arg
    call verify_frontend(source,p,d)
    call expect(d%code/=0,'cyclic component scan adapter guard')
    d=diagnostic_t()
    call evaluate_constant(p,e,v,d)
    call expect(d%code/=0,'cyclic component scan runtime guard')
    print *, 'PASS: numeric-model adapter/runtime checks:',checks
contains
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok)return
        print *,'FAIL: ',label
        if(allocated(d%message))print *,d%message
        error stop 1
    end subroutine
    integer function find_call(name) result(index)
        character(*),intent(in)::name
        integer::j
        index=0
        do j=1,p%ne
            if(p%expressions(j)%kind==ex_call.and.p%expressions(j)%op==name)index=j
        end do
        if(index==0)error stop 'inquiry missing'
    end function
    subroutine fixture(name,typ,kind)
        character(*),intent(in)::name
        integer,intent(in)::typ,kind
        p=program_t();d=diagnostic_t()
        allocate(p%symbols(0),p%expressions(2),p%code(0));p%ne=2
        p%expressions(1)=expr_t(kind=ex_literal,typ=typ,real_kind=kind, &
            value=value_t(tag=typ,real_kind=kind))
        p%expressions(2)=expr_t(kind=ex_call,typ=typ,real_kind=kind,op=name,args=[1])
        if(name=='radix')then
            p%expressions(2)%typ=ty_integer;p%expressions(2)%real_kind=4
        end if
    end subroutine
end program
