! SPDX-License-Identifier: MIT
program test_iso_integer_availability
    use, intrinsic :: iso_fortran_env, only:int64
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program,evaluate_constant
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    type(value_t)::v
    character(*),parameter::nl=new_line('a')
    character(:),allocatable::source,remote
    integer::family,mutation,checks,e
    integer(int64)::expected
    checks=0
    do family=1,2
        select case(family)
        case(1);remote='int8';expected=-1
        case(2);remote='int16';expected=-1
        end select
        source='program p'//nl//'use,intrinsic::iso_fortran_env,only:local=>'//remote//nl// &
            'implicit none'//nl//'end program'
        do mutation=0,37
            call parse_subset(source,p,d)
            call expect(d%code==0,'parse baseline')
            call expect(p%ns==1,'one import symbol')
            associate(s=>p%symbols(1))
            select case(mutation)
            case(1);s%intrinsic_import=''
            case(2);s%intrinsic_import='wrong'
            case(3);s%is_intrinsic=.false.
            case(4);s%is_parameter=.false.
            case(5);s%parameter_ready=.false.
            case(6);s%typ=ty_real
            case(7);s%real_kind=8
            case(8);s%rank=1
            case(9);s%constant_value%tag=ty_real
            case(10);s%constant_value%real_kind=8
            case(11);s%constant_value%i=expected+1
            case(12);allocate(s%constant_values(0))
            case(13);s%constant_value%s=''
            case(14);allocate(s%constant_value%record)
            case(15);s%is_dummy=.true.
            case(16);s%is_optional=.true.
            case(17);s%dummy_intent=1
            case(18);s%is_class=.true.
            case(19);s%is_allocatable=.true.
            case(20);s%is_pointer=.true.
            case(21);s%is_target=.true.
            case(22);s%is_saved=.true.
            case(23);s%is_automatic=.true.
            case(24);s%assumed_shape=.true.
            case(25);s%deferred_character=.true.
            case(26);s%initializer_expr=1
            case(27);s%kind_expr=1
            case(28);s%length_expr=1
            case(29);s%character_len=1
            case(30);s%lower_expr=1
            case(31);s%upper_expr2=1
            case(32);s%lower_expr3=1
            case(33);s%lower_bound=0
            case(34);s%upper_bound2=0
            case(35);s%upper_bound3=0
            case(36);s%scope=1
            case(37);s%scope=-1
            end select
            end associate
            call verify_frontend(source,p,d)
            call expect((d%code==0).eqv.(mutation==0),'adapter rejects forged import')
            d=diagnostic_t()
            call execute_program(p,d)
            call expect((d%code==0).eqv.(mutation==0),'runtime validates even unused import')
            e=p%ne+1;p%ne=e
            p%expressions(e)=expr_t(kind=ex_variable,typ=ty_integer,symbol=1)
            d=diagnostic_t()
            call evaluate_constant(p,e,v,d)
            call expect((d%code==0).eqv.(mutation==0),'constant import validation')
            if(mutation==0)call expect(v%tag==ty_integer.and.v%real_kind==4.and.v%i==expected,'constant value')
            e=p%ne+1;p%ne=e
            p%expressions(e)=expr_t(kind=ex_call,op='kind',typ=ty_integer,args=[e-1])
            d=diagnostic_t()
            call evaluate_constant(p,e,v,d)
            call expect((d%code==0).eqv.(mutation==0),'KIND cannot bypass import descriptor')
            if(mutation==0)call expect(v%i==4,'import INTEGER kind')
        end do
    end do
    ! Same-valued remote entities remain distinct source identities.
    source='program p'//nl//'use,intrinsic::iso_fortran_env,only:local=>int8'//nl//'end program'
    call parse_subset(source,p,d)
    call expect(d%code==0,'identity parse')
    p%symbols(1)%intrinsic_import='int16'
    call verify_frontend(source,p,d)
    call expect(d%code/=0,'same-value remote identity mutation')
    ! Rank-one INTEGER_KINDS cache and ownership, including unused imports.
    source='program p'//nl//'use,intrinsic::iso_fortran_env,only:ks=>integer_kinds'//nl//'end program'
    do mutation=0,48
        call parse_subset(source,p,d)
        call expect(d%code==0,'vector import parse')
        call expect(p%ns==1,'one vector import')
        associate(s=>p%symbols(1))
        select case(mutation)
        case(1);s%intrinsic_import='int64'
        case(2);s%intrinsic_import='wrong'
        case(3);s%is_intrinsic=.false.
        case(4);s%is_parameter=.false.
        case(5);s%parameter_ready=.false.
        case(6);s%typ=ty_real
        case(7);s%real_kind=8
        case(8);s%rank=0
        case(9);s%rank=2
        case(10);deallocate(s%constant_values)
        case(11);s%constant_values=[value_t::]
        case(12);s%constant_values=[value_t(tag=ty_integer,i=4_int64)]
        case(13);s%constant_values=[value_t(tag=ty_integer,i=4_int64),value_t(tag=ty_integer,i=8_int64),value_t(tag=ty_integer,i=16_int64)]
        case(14);s%constant_values(1)%i=1
        case(15);s%constant_values(2)%i=4
        case(16);s%constant_values(1)%tag=ty_real
        case(17);s%constant_values(2)%real_kind=8
        case(18);s%constant_values(1)%r=1.0
        case(19);s%constant_values(2)%l=.true.
        case(20);s%constant_values(1)%s=''
        case(21);allocate(s%constant_values(2)%record)
        case(22);s%constant_value%tag=ty_integer
        case(23);s%constant_value%i=4
        case(24);s%constant_value%real_kind=8
        case(25);s%constant_value%r=1.0
        case(26);s%constant_value%l=.true.
        case(27);s%constant_value%s=''
        case(28);allocate(s%constant_value%record)
        case(29);s%is_dummy=.true.
        case(30);s%is_optional=.true.
        case(31);s%dummy_intent=1
        case(32);s%is_class=.true.
        case(33);s%is_allocatable=.true.
        case(34);s%is_pointer=.true.
        case(35);s%is_target=.true.
        case(36);s%is_saved=.true.
        case(37);s%is_automatic=.true.
        case(38);s%assumed_shape=.true.
        case(39);s%deferred_character=.true.
        case(40);s%initializer_expr=1
        case(41);s%kind_expr=1
        case(42);s%length_expr=1
        case(43);s%lower_expr=1
        case(44);s%lower_bound=0
        case(45);s%upper_bound=3
        case(46);s%upper_bound2=2
        case(47);s%scope=1
        case(48);s%scope=-1
        end select
        end associate
        call verify_frontend(source,p,d)
        call expect((d%code==0).eqv.(mutation==0),'vector adapter')
        d=diagnostic_t();call execute_program(p,d)
        call expect((d%code==0).eqv.(mutation==0),'unused vector runtime')
        e=p%ne+1;p%ne=e
        p%expressions(e)=expr_t(kind=ex_variable,typ=ty_integer,symbol=1,rank=1,extent=2_int64)
        e=p%ne+1;p%ne=e
        p%expressions(e)=expr_t(kind=ex_call,op='kind',typ=ty_integer,args=[e-1])
        d=diagnostic_t();call evaluate_constant(p,e,v,d)
        call expect((d%code==0).eqv.(mutation==0),'vector KIND cannot bypass descriptor')
        if(mutation==0)call expect(v%i==4,'vector default INTEGER kind')
    end do
    print *, 'PASS: ISO integer availability independent assertions:',checks
contains
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok)return
        print *,family,mutation,label
        if(allocated(d%message))print *,d%message
        error stop 'ISO_FORTRAN_ENV import invariant failure'
    end subroutine
end program
