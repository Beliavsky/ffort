! SPDX-License-Identifier: MIT
program test_trigonometric_intrinsics
    use, intrinsic :: iso_fortran_env, only: real32,real64
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:evaluate_constant,execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    type(value_t)::v
    character(*),parameter::nl=new_line('a')
    character(:),allocatable::source,arg
    character(3)::name
    integer::family,mutation,e,j,checks,rk,mode,kindex,form
    real(real64)::want
    checks=0
    do family=1,3
        select case(family)
        case(1);name='sin'
        case(2);name='cos'
        case(3);name='tan'
        end select
        do rk=4,8,4
            arg='0.75'
            if(rk==8) arg='0.75d0'
            source='program p'//nl//'implicit none'//nl//'print *,'//name//'(x='//arg//')'//nl//'end program'
            do mutation=0,13
                call parse_subset(source,p,d)
                call expect(d%code==0,'source parses')
                e=0
                do j=1,p%ne
                    if(p%expressions(j)%op==name)e=j
                end do
                call expect(e>0,'call exists')
                select case(mutation)
                case(1);p%expressions(e)%typ=ty_integer
                case(2);p%expressions(e)%real_kind=12-rk
                case(3);p%expressions(e)%rank=1;p%expressions(e)%extent=0
                case(4);p%expressions(e)%args(1)=0
                case(5);p%expressions(e)%args=[integer::]
                case(6);p%expressions(e)%args(1)=p%ne+1
                case(7);p%expressions(p%expressions(e)%args(1))%typ=ty_integer
                case(8);p%expressions(e)%args=[p%expressions(e)%args,p%expressions(e)%args]
                case(9);p%expressions(e)%extent=1
                case(10);p%expressions(e)%dims=[1,2,1]
                case(11);p%expressions(e)%args(1)=e
                case(12);deallocate(p%expressions(e)%args)
                case(13);p%expressions(e)%real_kind=16
                end select
                call verify_frontend(source,p,d)
                call expect((d%code==0).eqv.(mutation==0),'independent adapter mutation')
                do mode=1,2
                    d=diagnostic_t()
                    if(mode==1)then
                        call evaluate_constant(p,e,v,d)
                    else
                        kindex=p%ne+1;p%ne=kindex
                        p%expressions(kindex)=expr_t(kind=ex_call,op='kind',typ=ty_integer,args=[e])
                        call evaluate_constant(p,kindex,v,d)
                    end if
                    call expect((d%code==0).eqv.(mutation==0),'runtime and unevaluated KIND mutation')
                    if(mutation/=0)cycle
                    if(mode==2)then
                        call expect(v%tag==ty_integer.and.v%i==rk,'KIND result')
                        cycle
                    end if
                    if(rk==4)then
                        select case(family)
                        case(1);want=real(sin(0.75_real32),real64)
                        case(2);want=real(cos(0.75_real32),real64)
                        case(3);want=real(tan(0.75_real32),real64)
                        end select
                    else
                        select case(family)
                        case(1);want=sin(0.75_real64)
                        case(2);want=cos(0.75_real64)
                        case(3);want=tan(0.75_real64)
                        end select
                    end if
                    call expect(v%tag==ty_real.and.v%real_kind==rk.and.v%r==want,'kind-preserving value')
                end do
            end do
        end do
        ! Empty results still validate descriptors and intrinsic arity before
        ! execution. This must not become a zero-iteration validation bypass.
        source='program p'//nl//'real(8)::z(0)'//nl//'print *,'//name//'(z)'//nl//'end program'
        do mutation=0,4
            call parse_subset(source,p,d)
            call expect(d%code==0,'empty source parses')
            do j=1,p%ne
                if(p%expressions(j)%op==name)e=j
            end do
            select case(mutation)
            case(1);p%expressions(e)%real_kind=4
            case(2);p%expressions(e)%typ=ty_integer
            case(3);p%expressions(e)%args=[p%expressions(e)%args,p%expressions(e)%args]
            case(4);p%expressions(e)%rank=0
            end select
            call execute_program(p,d)
            call expect((d%code==0).eqv.(mutation==0),'empty result validation')
        end do
    end do
    ! Enclosing static zero-sized arithmetic and reductions must not hide
    ! malformed calls, and metadata validation must not read undefined data.
    do family=1,3
        select case(family)
        case(1);name='sin'
        case(2);name='cos'
        case(3);name='tan'
        end select
        do form=1,4
            select case(form)
            case(1);arg=name//'(z)+z'
            case(2);arg='sum('//name//'(z)+z)'
            case(3);arg='abs(-'//name//'(z))'
            case(4);arg='x+'//name//'(z)'
            end select
            source='program p'//nl//'real(8)::z(0),x'//nl//'print *,'//arg//nl//'end program'
            do mutation=0,5
                call parse_subset(source,p,d)
                call expect(d%code==0,'nested empty source parses')
                do j=1,p%ne
                    if(p%expressions(j)%op==name)e=j
                end do
                select case(mutation)
                case(1);p%expressions(e)%real_kind=4
                case(2);p%expressions(e)%typ=ty_integer
                case(3);p%expressions(e)%args=[p%expressions(e)%args,p%expressions(e)%args]
                case(4);p%expressions(e)%rank=0
                case(5);p%expressions(e)%args(1)=e
                end select
                call execute_program(p,d)
                call expect((d%code==0).eqv.(mutation==0),'nested empty result validation')
            end do
        end do
    end do
    source='program p'//nl//'print *,kind(sin(1000.0)),kind(cos(1000.0d0))'//nl//'end program'
    call parse_subset(source,p,d)
    call expect(d%code==0,'unevaluated constants parse')
    call verify_frontend(source,p,d)
    call expect(d%code==0,'unevaluated constants verify')
    do j=1,p%ne
        if(p%expressions(j)%op/='kind')cycle
        call evaluate_constant(p,j,v,d)
        e=p%expressions(j)%args(1)
        call expect(d%code==0.and.v%i==p%expressions(e)%real_kind,'nested KIND stays unevaluated')
    end do
    print *, 'PASS: trigonometric adapter, runtime, KIND and empty-result assertions:',checks
contains
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok)return
        print *, 'FAIL: ',label,' intrinsic ',name,' kind ',rk,' mutation ',mutation,' mode ',mode
        if(allocated(d%message))print *,d%message
        error stop 1
    end subroutine
end program
