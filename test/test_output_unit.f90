! SPDX-License-Identifier: MIT
program test_output_unit
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
    integer::family,mutation,checks,e,pc
    character(:),allocatable::source_plain
    integer(int64)::expected
    checks=0
    do family=1,1
        select case(family)
        case(1);remote='output_unit';expected=processor_output_unit
        case(2);remote='real64';expected=8
        case(3);remote='int32';expected=4
        case(4);remote='int64';expected=8
        case(5);remote='real128';expected=-1
        end select
        source='program p'//nl//'use iso_fortran_env,only:local=>'//remote//nl// &
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
    source='program p'//nl//'use,intrinsic::iso_fortran_env,only:local=>real64'//nl//'end program'
    call parse_subset(source,p,d)
    call expect(d%code==0,'identity parse')
    p%symbols(1)%intrinsic_import='int64'
    call verify_frontend(source,p,d)
    call expect(d%code/=0,'same-value remote identity mutation')
    ! The imported source identity is retained on standard-output WRITE.
    source='program p'//nl//'use iso_fortran_env,only:u=>output_unit,k=>int32'//nl// &
        "write(u,'(a)',advance='no') ''"//nl//'end program'
    do mutation=0,18
        call parse_subset(source,p,d)
        call expect(d%code==0,'stdout source parse')
        pc=1
        call expect(p%code(pc)%op==op_print.and.p%code(pc)%symbol==1,'stdout source binding')
        select case(mutation)
        case(1);p%code(pc)%symbol=0 ! Safe stdout, but loses source identity.
        case(2);p%code(pc)%symbol=2 ! INT32 is not a unit despite being INTEGER.
        case(3);p%code(pc)%symbol=p%ns+1
        case(4);p%code(pc)%symbol=-1
        case(5);p%code(pc)%a=1
        case(6);p%code(pc)%b=1
        case(7);p%code(pc)%c=1
        case(8);p%code(pc)%d=1
        case(9);p%code(pc)%target=1
        case(10);p%code(pc)%third=1
        case(11);p%code(pc)%generic_id=1
        case(12);p%code(pc)%component=1
        case(13);p%code(pc)%bound_type=1
        case(14);p%code(pc)%bound_binding=1
        case(15);p%code(pc)%construct_name='forged'
        case(16);p%symbols(1)%constant_value%i=processor_output_unit+1
        case(17);p%symbols(1)%intrinsic_import='int32';p%symbols(1)%constant_value%i=4
        case(18);p%symbols(1)%scope=1
        end select
        call verify_frontend(source,p,d)
        call expect((d%code==0).eqv.(mutation==0),'stdout adapter mutation')
        d=diagnostic_t()
        call execute_program(p,d)
        call expect((d%code==0).eqv.(mutation==0.or.mutation==1),'stdout runtime mutation')
    end do
    ! Omitted nature must not be forged into intrinsic when a source module wins.
    source_plain='module iso_fortran_env'//nl//'integer,parameter::output_unit=77'//nl// &
        'end module'//nl//'program p'//nl//'use iso_fortran_env,only:output_unit'//nl//'end program'
    source='module iso_fortran_env'//nl//'integer,parameter::output_unit=77'//nl// &
        'end module'//nl//'program p'//nl//'use,intrinsic::iso_fortran_env,only:output_unit'//nl//'end program'
    call parse_subset(source,p,d)
    call expect(d%code==0,'explicit intrinsic shadow baseline')
    call verify_frontend(source,p,d)
    call expect(d%code==0,'explicit nature remains supported')
    call verify_frontend(source_plain,p,d)
    call expect(d%code/=0,'plain source nature cannot be forged')
    print *, 'PASS: OUTPUT_UNIT independent assertions:',checks
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
