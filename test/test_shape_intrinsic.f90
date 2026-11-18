! SPDX-License-Identifier: MIT
program test_shape_intrinsic
    use, intrinsic :: iso_fortran_env, only: int64
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: evaluate_constant_array,evaluate_constant,execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    type(value_t),allocatable::v(:)
    type(value_t)::scalar
    character(*),parameter::nl=new_line('a')
    character(:),allocatable::source
    integer::e,j,k,mutation,form,checks,n
    checks=0
    do form=1,3
        if(form==1)then
            source='program p'//nl//'integer::a(2,3)'//nl//'print *,shape(kind=8,source=a)'//nl//'end program'
        else if(form==2)then
            source='program p'//nl//'print *,shape(source=42,kind=8)'//nl//'end program'
        else
            source='program p'//nl//'print *,sum(shape(source=42,kind=8))'//nl//'end program'
        end if
        do mutation=0,19
            call parse_subset(source,p,d)
            call expect(d%code==0,'parse valid source')
            e=0
            do j=1,p%ne
                if(p%expressions(j)%op=='shape')e=j
            end do
            call expect(e>0,'SHAPE expression exists')
            select case(mutation)
            case(1);p%expressions(e)%typ=ty_logical
            case(2);p%expressions(e)%real_kind=4
            case(3);p%expressions(e)%rank=0
            case(4);p%expressions(e)%extent=99
            case(5);p%expressions(e)%dims=[99_int64,0_int64,0_int64]
            case(6);p%expressions(e)%args(1)=0
            case(7);p%expressions(e)%args(1)=p%ne+1
            case(8);p%expressions(e)%args(1)=e
            case(9);deallocate(p%expressions(e)%args)
            case(10);p%expressions(e)%args=[integer::]
            case(11);p%expressions(e)%args=[p%expressions(e)%args,p%expressions(e)%args]
            case(12);p%expressions(e)%real_kind=16
            case(13)
                k=p%expressions(e)%args(size(p%expressions(e)%args))
                p%expressions(k)%value%i=16
            case(14)
                k=p%expressions(e)%args(2);p%expressions(k)%typ=ty_logical
            case(15)
                k=p%expressions(e)%args(2);p%expressions(k)%rank=1;p%expressions(k)%extent=1
            case(16);p%expressions(e)%intrinsic_mask=1
            case(17);p%expressions(p%expressions(e)%args(1))%rank=4
            case(18);p%expressions(p%expressions(e)%args(1))%typ=0
            case(19)
                k=p%expressions(e)%args(2);p%expressions(k)%kind=ex_variable
                p%expressions(k)%symbol=0
            end select
            call verify_frontend(source,p,d)
            call expect((d%code==0).eqv.(mutation==0),'adapter mutation rejection')
            d=diagnostic_t()
            call evaluate_constant_array(p,e,v,d)
            call expect((d%code==0).eqv.(mutation==0),'runtime mutation rejection')
            if(form==3)then
                d=diagnostic_t()
                call execute_program(p,d)
                call expect((d%code==0).eqv.(mutation==0),'enclosing scalar empty SUM mutation rejection')
            end if
            n=p%ne+1;p%ne=n
            p%expressions(n)=expr_t(kind=ex_call,op='kind',typ=ty_integer,args=[e])
            d=diagnostic_t()
            call evaluate_constant(p,n,scalar,d)
            call expect((d%code==0).eqv.(mutation==0),'KIND wrapper mutation rejection')
            if(mutation==0)call expect(scalar%i==8,'KIND wrapper result')
            if(mutation/=0)cycle
            call expect(allocated(v),'result allocated')
            if(form==1)then
                call expect(size(v)==2,'rank two length')
                call expect(all(v%tag==ty_integer).and.all(v%real_kind==8),'integer kind eight values')
                call expect(v(1)%i==2.and.v(2)%i==3,'extents independently expected')
            else
                call expect(size(v)==0,'scalar empty result')
            end if
        end do
    end do
    ! A syntactically nonconstant KIND must not become valid just because its
    ! value happens to be initialized to a supported kind.
    source='program p'//nl//'integer::k=8'//nl//'print *,k,shape(42,8)'//nl//'end program'
    call parse_subset(source,p,d)
    call expect(d%code==0,'nonconstant KIND mutation setup')
    e=0;k=0
    do j=1,p%ne
        if(p%expressions(j)%op=='shape')e=j
        if(p%expressions(j)%kind==ex_variable)k=j
    end do
    call expect(e>0.and.k>0,'nonconstant KIND nodes')
    p%expressions(e)%args(2)=k
    call verify_frontend(source,p,d)
    call expect(d%code/=0,'adapter rejects nonconstant KIND')
    d=diagnostic_t()
    call evaluate_constant_array(p,e,v,d)
    call expect(d%code/=0,'runtime rejects nonconstant KIND')
    ! Never subtract hostile bounds before validating the bounded domain.
    source='program p'//nl//'integer::a(2)'//nl//'print *,shape(a)'//nl//'end program'
    call parse_subset(source,p,d)
    call expect(d%code==0,'forged bounds setup')
    do j=1,p%ne
        if(p%expressions(j)%op=='shape')e=j
    end do
    k=p%expressions(p%expressions(e)%args(1))%symbol
    p%symbols(k)%lower_bound=-huge(0_int64)-1_int64
    p%symbols(k)%upper_bound=huge(0_int64)
    d=diagnostic_t()
    call evaluate_constant_array(p,e,v,d)
    call expect(d%code/=0,'runtime rejects overflow-sized static bounds')
    print *, 'PASS: SHAPE intrinsic assertions:',checks
contains
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok)return
        print *, 'FAIL: ',label,' mutation ',mutation,' form ',form
        if(allocated(d%message))print *,d%message
        error stop 1
    end subroutine
end program
