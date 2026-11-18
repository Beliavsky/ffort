! SPDX-License-Identifier: MIT
program test_erf_bessel
    use, intrinsic :: iso_fortran_env,only:int64,real64
    use, intrinsic :: ieee_arithmetic,only:ieee_value,ieee_quiet_nan,ieee_positive_inf
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    character(*),parameter::nl=new_line('a')
    character(16),parameter::names(7)=[character(16)::'erf','bessel_j0','bessel_j1','bessel_jn','bessel_y0','bessel_y1','bessel_yn']
    character(:),allocatable::name,src,args,empty,inquiry,scalar,shadow,prefix
    type(program_t)::p,q
    type(diagnostic_t)::d
    integer::family,j,g,i,child,n,checks
    checks=0
    do family=1,7
        name=trim(names(family));prefix='';n=1
        if(name=='bessel_jn'.or.name=='bessel_yn')then
            prefix='2_8,';n=2
        end if
        args=prefix//'x'
        src='program p'//nl//'implicit none'//nl//'real(8)::x(2),y(2)'//nl// &
            'x=[1d0,2d0]'//nl//'y='//name//'('//args//')'//nl//'end program'
        call parse_subset(src,p,d);call okay('parse')
        call verify_frontend(src,p,d);call okay('adapter')
        call execute_program(p,d);call okay('execute');checks=checks+3
        g=find_call(p,name)
        do j=1,14
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
            case(9);e%args=[e%args,e%args(1)]
            case(10);e%args(n)=0
            case(11);e%args(n)=g
            case(12);q%expressions(e%args(n))%typ=ty_integer
            case(13);q%expressions(e%args(n))%real_kind=16
            case(14)
                if(n==2)then
                    q%expressions(e%args(1))%typ=ty_real
                else
                    q%expressions(e%args(1))%rank=4
                end if
            end select
            end associate
            d=diagnostic_t();call verify_frontend(src,q,d)
            if(d%code==0)error stop 'adapter admitted forged ERF/Bessel'
            d=diagnostic_t();call execute_program(q,d)
            if(d%code==0)error stop 'runtime admitted forged ERF/Bessel'
            checks=checks+2
        end do
        empty='program p'//nl//'implicit none'//nl//'real(8)::x(0),y(0)'//nl// &
            'y='//name//'('//args//')+1d0'//nl//'end program'
        call parse_subset(empty,q,d);call okay('empty parse')
        call verify_frontend(empty,q,d);call okay('empty adapter')
        call execute_program(q,d);call okay('empty execute');checks=checks+3
        g=find_call(q,name);q%expressions(g)%intrinsic_mask=1
        d=diagnostic_t();call execute_program(q,d)
        if(d%code==0)error stop 'empty skipped ERF/Bessel metadata'
        checks=checks+1
        inquiry='program p'//nl//'implicit none'//nl//'real(8)::x'//nl// &
            'if(kind('//name//'('//args//'))/=8) error stop 1'//nl//'end program'
        call parse_subset(inquiry,q,d);call okay('KIND parse')
        call verify_frontend(inquiry,q,d);call okay('KIND adapter')
        call execute_program(q,d);call okay('KIND execute');checks=checks+3
        g=find_call(q,name);q%expressions(g)%real_kind=4
        d=diagnostic_t();call execute_program(q,d)
        if(d%code==0)error stop 'KIND skipped ERF/Bessel metadata'
        checks=checks+1
        scalar='program p'//nl//'implicit none'//nl//'real(8)::y'//nl// &
            'y='//name//'('//prefix//'1d0)'//nl//'end program'
        call parse_subset(scalar,p,d);call okay('scalar parse')
        g=find_call(p,name);child=p%expressions(g)%args(n)
        do j=1,2
            q=p
            if(j==1)q%expressions(child)%value%r=ieee_value(0d0,ieee_quiet_nan)
            if(j==2)q%expressions(child)%value%r=ieee_value(0d0,ieee_positive_inf)
            d=diagnostic_t();call execute_program(q,d)
            if(d%code==0)error stop 'nonfinite ERF/Bessel value admitted'
            checks=checks+1
        end do
        ! Same-typed source function cannot be forged into an intrinsic call.
        if(n==1) then
            shadow='program p'//nl//'implicit none'//nl//'real(8)::y'//nl// &
                'y='//name//'(1d0)'//nl//'contains'//nl//'real(8) function '//name//'(x)'//nl// &
                'real(8),intent(in)::x'//nl//name//'=x+1d0'//nl//'end function'//nl//'end program'
        else
            shadow='program p'//nl//'implicit none'//nl//'real(8)::y'//nl// &
                'y='//name//'(2_8,1d0)'//nl//'contains'//nl//'real(8) function '//name//'(n,x)'//nl// &
                'integer(8),intent(in)::n'//nl//'real(8),intent(in)::x'//nl//name//'=x+n'//nl//'end function'//nl//'end program'
        end if
        call parse_subset(shadow,q,d);call okay('shadow parse')
        call verify_frontend(shadow,q,d);call okay('shadow adapter')
        do i=1,q%ne
            if(q%expressions(i)%kind/=ex_user_call)cycle
            q%expressions(i)%kind=ex_call;q%expressions(i)%symbol=0;q%expressions(i)%op=name
            exit
        end do
        d=diagnostic_t();call verify_frontend(shadow,q,d)
        if(d%code==0)error stop 'source-bound function forged intrinsic'
        if(index(d%message,'shadowed by a source declaration')==0)error stop 'missing source-binding diagnostic'
        checks=checks+1
    end do
    print *,'PASS: ERF/Bessel native checks:',checks
contains
    integer function find_call(p,name) result(g)
        type(program_t),intent(in)::p
        character(*),intent(in)::name
        integer::i
        g=0
        do i=1,p%ne
            if(p%expressions(i)%kind==ex_call.and.p%expressions(i)%op==name)g=i
        end do
        if(g==0)error stop 'intrinsic call missing'
    end function
    subroutine okay(stage)
        character(*),intent(in)::stage
        if(d%code/=0)then
            print *,stage,d%message
            error stop 'ERF/Bessel native failure'
        end if
    end subroutine
end program
