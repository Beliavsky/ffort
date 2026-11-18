! SPDX-License-Identifier: MIT
program test_erfc_scaled
    use, intrinsic :: iso_fortran_env, only:int64,real32,real64
    use, intrinsic :: ieee_arithmetic, only:ieee_value,ieee_quiet_nan,ieee_positive_inf
    use fi_ir
    use fi_parser, only:parse_subset
    use fi_frontend, only:verify_frontend
    use fi_runtime, only:execute_program
    use fortfront_compiler
    use fortfront_ast, only:call_or_subscript_node
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::src='program p'//nl//'implicit none'//nl// &
        'real(8)::x(2)'//nl//'real(8)::y(2)'//nl//'x=[1d0,2d0]'//nl// &
        'y=erfc_scaled(x)'//nl//'if(any(y<=0d0)) error stop 1'//nl//'end program'
    character(*),parameter::empty='program p'//nl//'implicit none'//nl// &
        'real::x(0)'//nl//'real::y(0)'//nl//'y=erfc_scaled(x)+1.'//nl//'end program'
    character(*),parameter::inquiry='program p'//nl//'implicit none'//nl// &
        'real(8)::x'//nl//'if(kind(erfc_scaled(x))/=8) error stop 1'//nl//'end program'
    character(*),parameter::scalar='program p'//nl//'implicit none'//nl// &
        'real(8)::x'//nl//'x=erfc_scaled(1d0)'//nl//'end program'
    character(*),parameter::shadow='program p'//nl//'implicit none'//nl// &
        'real(8)::answer'//nl//'answer=erfc_scaled(1d0)'//nl//'contains'//nl// &
        'real(8) function erfc_scaled(x)'//nl//'real(8),intent(in)::x'//nl//'erfc_scaled=x+1d0'//nl// &
        'end function'//nl//'end program'
    character(*),parameter::scalar4='program p'//nl//'implicit none'//nl// &
        'real::x'//nl//'x=erfc_scaled(1.)'//nl//'end program'
    real(real64)::cut
    type(program_t)::p,q
    type(diagnostic_t)::d
    type(compiler_frontend_options_t)::opts
    type(compiler_frontend_result_t)::front
    type(resolved_type_query_t)::typ
    integer::g,j,i,checks,seen,child
    checks=0
    call parse_subset(src,p,d);call okay('parse')
    call verify_frontend(src,p,d);call okay('adapter')
    call execute_program(p,d);call okay('runtime');checks=checks+3
    g=find_erfc_scaled(p)
    do j=1,12
        q=p
        associate(e=>q%expressions(g))
        select case(j)
        case(1);e%typ=ty_logical
        case(2);e%real_kind=4
        case(3);e%rank=0
        case(4);e%extent=0_int64
        case(5);e%dims(1)=2_int64
        case(6);e%intrinsic_mask=1
        case(7);deallocate(e%args)
        case(8);deallocate(e%args);allocate(e%args(0))
        case(9);e%args=[e%args(1),e%args(1)]
        case(10);e%args(1)=0
        case(11);e%args(1)=g
        case(12);q%expressions(e%args(1))%typ=ty_integer
        end select
        end associate
        d=diagnostic_t();call verify_frontend(src,q,d)
        if(d%code==0) error stop 'adapter admitted forged ERFC_SCALED'
        d=diagnostic_t();call execute_program(q,d)
        if(d%code==0) error stop 'runtime admitted forged ERFC_SCALED'
        checks=checks+2
    end do
    call parse_subset(empty,q,d);call okay('empty parse')
    call verify_frontend(empty,q,d);call okay('empty adapter')
    call execute_program(q,d);call okay('empty runtime');checks=checks+3
    g=find_erfc_scaled(q);q%expressions(g)%intrinsic_mask=1
    d=diagnostic_t();call execute_program(q,d)
    if(d%code==0) error stop 'empty enclosing expression skipped ERFC_SCALED validation'
    checks=checks+1
    call parse_subset(inquiry,q,d);call okay('inquiry parse')
    call verify_frontend(inquiry,q,d);call okay('inquiry adapter')
    call execute_program(q,d);call okay('inquiry runtime');checks=checks+3
    g=find_erfc_scaled(q);q%expressions(g)%real_kind=4
    d=diagnostic_t();call execute_program(q,d)
    if(d%code==0) error stop 'KIND skipped ERFC_SCALED validation'
    checks=checks+1
    call parse_subset(scalar,p,d);call okay('scalar parse')
    call verify_frontend(scalar,p,d);call okay('scalar adapter')
    call execute_program(p,d);call okay('scalar runtime');checks=checks+3
    g=find_erfc_scaled(p);child=p%expressions(g)%args(1)
    do j=1,2
        q=p
        if(j==1) q%expressions(child)%value%r=ieee_value(0.0_real64,ieee_quiet_nan)
        if(j==2) q%expressions(child)%value%r=ieee_value(0.0_real64,ieee_positive_inf)
        d=diagnostic_t();call execute_program(q,d)
        if(d%code==0) error stop 'ERFC_SCALED bypassed finite-value policy'
        if(index(d%message,'non-finite')==0) error stop 'missing finite-value rejection'
        checks=checks+1
    end do
    ! Exact finite-result boundaries and nonzero subnormal positive tails.
    do j=1,2
        if(j==1) then
            call parse_subset(scalar4,p,d);cut=-9.3824138641357421875_real64
        else
            call parse_subset(scalar,p,d);cut=-26.628735713751489_real64
        end if
        call okay('boundary parse');g=find_erfc_scaled(p);child=p%expressions(g)%args(1)
        q=p;q%expressions(child)%value%r=cut
        d=diagnostic_t();call execute_program(q,d);call okay('last finite negative')
        q=p
        if(j==1) then
            q%expressions(child)%value%r=real(nearest(real(cut,real32),-1.0_real32),real64)
        else
            q%expressions(child)%value%r=nearest(cut,-1.0_real64)
        end if
        d=diagnostic_t();call execute_program(q,d)
        if(d%code==0) error stop 'overflow neighbor admitted'
        if(index(d%message,'finite result range')==0) error stop 'overflow guard not used'
        q=p
        if(j==1) then
            q%expressions(child)%value%r=real(huge(0.0_real32),real64)
        else
            q%expressions(child)%value%r=huge(0.0_real64)
        end if
        d=diagnostic_t();call execute_program(q,d);call okay('positive finite tail')
        checks=checks+3
    end do
    call parse_subset(shadow,q,d);call okay('shadow parse')
    call verify_frontend(shadow,q,d);call okay('shadow adapter')
    call execute_program(q,d);call okay('shadow runtime');checks=checks+3
    do i=1,q%ne
        if(q%expressions(i)%kind/=ex_user_call) cycle
        q%expressions(i)%kind=ex_call;q%expressions(i)%op='erfc_scaled';q%expressions(i)%symbol=0
    end do
    d=diagnostic_t();call verify_frontend(shadow,q,d)
    if(d%code==0) error stop 'adapter accepted source-bound ERFC_SCALED as intrinsic'
    checks=checks+1
    opts%input_mode=INPUT_MODE_STANDARD;opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.;opts%run_semantics=.true.
    call compile_frontend_from_string(src,front,opts)
    if(.not.front%success()) error stop 'producer rejected ERFC_SCALED'
    seen=0
    do i=1,front%arena%entry_count
        if(.not.front%arena%has_node_at(i)) cycle
        select type(n=>front%arena%entries(i)%node)
        type is(call_or_subscript_node)
            if(n%name/='erfc_scaled') cycle
            typ=query_resolved_type(front%arena,i)
            if(.not.typ%found.or.typ%rank/=1.or.typ%type_kind/=TREAL.or.typ%kind_value/=8) &
                error stop 'producer ERFC_SCALED shape/type/kind wrong'
            seen=seen+1
        end select
    end do
    if(seen/=1) error stop 'producer ERFC_SCALED missing'
    checks=checks+1
    print *,'PASS: ERFC_SCALED metadata, empty/inquiry, finite-policy and producer checks:',checks
contains
    integer function find_erfc_scaled(prog) result(found)
        type(program_t),intent(in)::prog
        integer::k
        found=0
        do k=1,prog%ne
            if(prog%expressions(k)%kind==ex_call.and.prog%expressions(k)%op=='erfc_scaled') found=k
        end do
        if(found==0) error stop 'ERFC_SCALED call absent'
    end function
    subroutine okay(label)
        character(*),intent(in)::label
        if(d%code/=0) then
            print *,label,': ',d%message
            error stop 'ERFC_SCALED check failed'
        end if
    end subroutine
end program
