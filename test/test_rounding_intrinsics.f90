! SPDX-License-Identifier: MIT
program test_rounding_intrinsics
    use, intrinsic :: iso_fortran_env, only: int64,real32,real64
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: evaluate_constant,execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    type(value_t)::v
    character(*),parameter::nl=new_line('a')
    character(:),allocatable::source,op,call,expr
    integer::family,rk,mutation,mode,e,j,k,checks,form
    checks=0
    do family=1,4
        select case(family)
        case(1);op='nint'
        case(2);op='floor'
        case(3);op='ceiling'
        case(4);op='log10'
        end select
        do rk=4,8,4
            call=op//'(a=2.5d0,kind=4)'
            if(rk==8)call=op//'(kind=8,a=2.5d0)'
            if(family==4) then
                call=op//'(x=0.75)'
                if(rk==8)call=op//'(x=0.75d0)'
            end if
            source='program p'//nl//'print *,'//call//nl//'end program'
            do mutation=0,15
                call parse_subset(source,p,d)
                call expect(d%code==0,'parse')
                e=0
                do j=1,p%ne
                    if(p%expressions(j)%op==op)e=j
                end do
                call expect(e>0,'call found')
                select case(mutation)
                case(1);p%expressions(e)%typ=ty_logical
                case(2);p%expressions(e)%real_kind=12-rk
                case(3);p%expressions(e)%rank=1;p%expressions(e)%extent=0
                case(4);p%expressions(e)%args(1)=0
                case(5);p%expressions(e)%args=[integer::]
                case(6);p%expressions(e)%args(1)=p%ne+1
                case(7);p%expressions(p%expressions(e)%args(1))%typ=ty_integer
                case(8);p%expressions(e)%args=[p%expressions(e)%args,p%expressions(e)%args]
                case(9);p%expressions(e)%extent=1
                case(10);p%expressions(e)%dims=[1_int64,2_int64,1_int64]
                case(11);p%expressions(e)%args(1)=e
                case(12);deallocate(p%expressions(e)%args)
                case(13);p%expressions(e)%real_kind=16
                case(14)
                    if(family<4)then
                        k=p%expressions(e)%args(2);p%expressions(k)%value%i=16
                    else
                        p%expressions(p%expressions(e)%args(1))%real_kind=16
                    end if
                case(15)
                    if(family<4)then
                        k=p%expressions(e)%args(2);p%expressions(k)%rank=1;p%expressions(k)%extent=1
                    else
                        p%expressions(p%expressions(e)%args(1))%rank=1
                    end if
                end select
                call verify_frontend(source,p,d)
                call expect((d%code==0).eqv.(mutation==0),'adapter rejects mutation')
                do mode=1,2
                    d=diagnostic_t()
                    if(mode==1)then
                        call evaluate_constant(p,e,v,d)
                    else
                        k=p%ne+1;p%ne=k
                        p%expressions(k)=expr_t(kind=ex_call,op='kind',typ=ty_integer,args=[e])
                        call evaluate_constant(p,k,v,d)
                    end if
                    call expect((d%code==0).eqv.(mutation==0),'runtime rejects mutation')
                    if(mutation/=0)cycle
                    if(mode==2)then
                        call expect(v%tag==ty_integer.and.v%i==rk,'KIND result')
                    else if(family==4)then
                        call expect(v%tag==ty_real.and.v%real_kind==rk,'LOG10 type and kind')
                        if(rk==4)call expect(v%r==real(log10(0.75_real32),real64),'LOG10 REAL32 precision')
                        if(rk==8)call expect(abs(v%r-log10(0.75_real64))<= &
                            2*epsilon(1.0_real64)*abs(log10(0.75_real64)),'LOG10 REAL64 precision')
                    else
                        k=3
                        if(family==2)k=2
                        call expect(v%tag==ty_integer.and.v%real_kind==rk.and.v%i==k,'rounding result')
                    end if
                end do
            end do
        end do
        do form=1,4
            call=op//'(z)'
            select case(form)
            case(1);expr=call
            case(2);expr=call//'+z'
            case(3);expr='sum('//call//'+z)'
            case(4);expr='abs(-'//call//')'
            end select
            source='program p'//nl//'real(8)::z(0)'//nl//'print *,'//expr//nl//'end program'
            do mutation=0,5
                call parse_subset(source,p,d)
                call expect(d%code==0,'empty parse')
                do j=1,p%ne
                    if(p%expressions(j)%op==op)e=j
                end do
                select case(mutation)
                case(1);p%expressions(e)%real_kind=16
                case(2);p%expressions(e)%typ=ty_logical
                case(3);p%expressions(e)%args=[p%expressions(e)%args,p%expressions(e)%args,p%expressions(e)%args]
                case(4);p%expressions(e)%rank=0
                case(5);p%expressions(e)%args(1)=e
                end select
                call execute_program(p,d)
                call expect((d%code==0).eqv.(mutation==0),'empty metadata validation')
            end do
        end do
    end do
    print *, 'PASS: rounding and LOG10 assertions:',checks
contains
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok)return
        print *, 'FAIL: ',label,' intrinsic ',op,' kind ',rk,' mutation ',mutation,' mode ',mode
        if(allocated(d%message))print *,d%message
        error stop 1
    end subroutine
end program
