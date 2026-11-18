! SPDX-License-Identifier: MIT
! Direct public-IR checks, independent of source adapter/parser acceptance.
program test_constructor_random_runtime
    use, intrinsic :: iso_fortran_env, only: int64, real64
    use fi_ir
    use fi_runtime, only: execute_program,evaluate_constant
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    type(value_t)::v
    integer::j,e,a,b,c,k,which
    integer(int64)::state,expected
    ! Concatenate scalars and nested rank-one constructors and check reduction.
    do which=1,11
        call reset()
        a=literal(1.0_real64);b=literal(2.0_real64);c=literal(3.0_real64)
        k=constructor([b,c],2)
        e=constructor([a,k],3)
        p%code(1)%op=op_assign;p%code(1)%symbol=1;p%code(1)%a=e;p%nc=1
        select case(which)
        case(2);p%expressions(e)%args(1)=0
        case(3);p%expressions(e)%args(1)=e
        case(4);p%expressions(e)%rank=2
        case(5);p%expressions(e)%extent=2
        case(6);p%expressions(e)%dims(1)=4
        case(7);p%expressions(e)%typ=ty_logical
        case(8);p%expressions(k)%real_kind=4
        case(9);deallocate(p%expressions(e)%args)
        case(10);p%expressions(e)%args=[integer::]
        case(11);p%expressions(k)%rank=2
        end select
        if(which==1) then
            a=variable();b=call_expr('sum',[a],ty_real)
            c=literal(6.0_real64);call assert_equal(b,c)
        end if
        call execute_program(p,d)
        call expect(which==1,'constructor IR')
    end do
    ! KIND is an initialization inquiry: an undefined array's values are unused.
    do which=1,12
        call reset();a=variable();e=call_expr('kind',[a],ty_integer)
        select case(which)
        case(2);p%expressions(e)%args=[integer::]
        case(3);p%expressions(e)%args=[a,a]
        case(4);p%expressions(e)%args=[0]
        case(5);p%expressions(e)%args=[e]
        case(6);p%expressions(e)%typ=ty_real
        case(7);p%expressions(a)%real_kind=4
        case(8);deallocate(p%expressions(e)%args)
        case(9);p%expressions(a)%rank=0;p%expressions(a)%extent=0
        case(10)
            p%expressions(a)%kind=ex_user_call;p%expressions(a)%symbol=999
        case(11)
            p%expressions(a)%kind=ex_unary;p%expressions(a)%op='-';p%expressions(a)%left=a
        case(12)
            p%expressions(a)%kind=ex_unary;p%expressions(a)%op='-';p%expressions(a)%left=p%ne+1
        end select
        call evaluate_constant(p,e,v,d)
        call expect(which==1,'KIND IR')
        if(which==1.and.v%i/=8) error stop 'KIND value'
    end do
    ! A call draws exactly one value per element, with a shared explicit state.
    do which=1,11
        call reset();a=variable()
        p%code(1)%op=op_random_number;p%code(1)%symbol=1;p%code(1)%a=a;p%nc=1
        state=104729_int64;expected=state
        do j=1,3
            expected=modulo(expected*16807_int64,2147483647_int64)
        end do
        select case(which)
        case(2);p%expressions(a)%parenthesized=.true.
        case(3);p%symbols(1)%is_parameter=.true.
        case(4);p%expressions(a)%typ=ty_integer
        case(5);p%expressions(a)%real_kind=4
        case(6);p%expressions(a)%symbol=0
        case(7);p%code(1)%a=0
        case(8);p%expressions(a)%rank=0;p%expressions(a)%extent=0
        case(9);p%expressions(a)%kind=ex_call
        case(10);p%symbols(1)%is_dummy=.true.;p%symbols(1)%dummy_intent=1
        end select
        if(which==1) then
            ! Last value must agree with the explicitly documented recurrence.
            b=integer_literal(3);c=new_expr(ex_element,ty_real)
            p%expressions(c)%symbol=1;p%expressions(c)%left=b
            b=literal(real(expected,real64)/2147483647.0_real64)
            call assert_equal(b,c)
        end if
        if(which==11) then
            call execute_program(p,d,max_steps=2_int64,random_state=state)
        else
            call execute_program(p,d,random_state=state)
        end if
        call expect(which==1,'RANDOM_NUMBER IR')
        if(which==1) then
            if(state/=expected) error stop 'incorrect generator sequence'
        else
            if(state/=104729_int64) error stop 'failed call advanced generator'
        end if
    end do
    ! Empty array: descriptor validated and no draws; deterministic reset.
    call reset();p%symbols(1)%upper_bound=0
    a=variable();p%expressions(a)%extent=0;p%expressions(a)%dims=0
    p%nc=1;p%code(1)%op=op_random_number;p%code(1)%symbol=1;p%code(1)%a=a
    state=104729_int64
    call execute_program(p,d,random_state=state)
    call expect(.true.,'empty harvest')
    if(state/=104729_int64) error stop 'empty harvest draws'
    call reset();a=variable()
    p%nc=1;p%code(1)%op=op_random_number;p%code(1)%symbol=1;p%code(1)%a=a
    b=integer_literal(1);c=new_expr(ex_element,ty_real)
    p%expressions(c)%symbol=1;p%expressions(c)%left=b
    expected=modulo(104729_int64*16807_int64,2147483647_int64)
    b=literal(real(expected,real64)/2147483647.0_real64);call assert_equal(b,c)
    call execute_program(p,d);call expect(.true.,'first default stream')
    d=diagnostic_t()
    call execute_program(p,d);call expect(.true.,'reset default stream')
    print '(a)','PASS: constructor, KIND and RANDOM_NUMBER runtime validation, values, budget and reset'
contains
    subroutine reset()
        p=program_t();d=diagnostic_t()
        allocate(p%symbols(1),p%expressions(100),p%code(20))
        p%ns=1;p%symbols(1)%name='x';p%symbols(1)%typ=ty_real
        p%symbols(1)%real_kind=8;p%symbols(1)%rank=1;p%symbols(1)%upper_bound=3
    end subroutine
    integer function new_expr(kind,typ) result(e)
        integer,intent(in)::kind,typ
        p%ne=p%ne+1;e=p%ne
        p%expressions(e)%kind=kind;p%expressions(e)%typ=typ
        if(typ==ty_real) p%expressions(e)%real_kind=8
    end function
    integer function literal(x) result(e)
        real(real64),intent(in)::x
        e=new_expr(ex_literal,ty_real)
        p%expressions(e)%value%tag=ty_real;p%expressions(e)%value%real_kind=8
        p%expressions(e)%value%r=x
    end function
    integer function integer_literal(x) result(e)
        integer,intent(in)::x
        e=new_expr(ex_literal,ty_integer)
        p%expressions(e)%value%tag=ty_integer;p%expressions(e)%value%i=x
    end function
    integer function variable() result(e)
        e=new_expr(ex_variable,ty_real)
        p%expressions(e)%symbol=1;p%expressions(e)%rank=1
        p%expressions(e)%extent=3;p%expressions(e)%dims=[3_int64,0_int64,1_int64]
    end function
    integer function constructor(args,n) result(e)
        integer,intent(in)::args(:),n
        e=new_expr(ex_constructor,ty_real);p%expressions(e)%args=args
        p%expressions(e)%rank=1;p%expressions(e)%extent=n;p%expressions(e)%dims=0_int64
    end function
    integer function call_expr(name,args,typ) result(e)
        character(*),intent(in)::name
        integer,intent(in)::args(:),typ
        e=new_expr(ex_call,typ);p%expressions(e)%op=name;p%expressions(e)%args=args
    end function
    subroutine assert_equal(a,b)
        integer,intent(in)::a,b
        integer::e,n
        e=new_expr(ex_binary,ty_logical);p%expressions(e)%op='/='
        p%expressions(e)%left=a;p%expressions(e)%right=b
        n=p%nc+1;p%code(n)%op=op_branch;p%code(n)%a=e;p%code(n)%target=n+2
        p%code(n+1)%op=op_error_stop;p%nc=n+1
    end subroutine
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        if(ok.eqv.(d%code==0)) return
        print *,label,which,d%code
        if(allocated(d%message)) print *,d%message
        error stop 'unexpected runtime result'
    end subroutine
end program
