! SPDX-License-Identifier: MIT
program test_derived_defaults
    use, intrinsic::iso_fortran_env,only:real64
    use, intrinsic::ieee_arithmetic,only:ieee_value,ieee_quiet_nan
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(:),allocatable::source
    integer::mutation,root,checks
    checks=0
    source='module types'//nl//'implicit none'//nl//'type::dt'//nl//'real::y=1000.0'//nl// &
        'end type'//nl//'end module'//nl//'program p'//nl//'use types'//nl//'implicit none'//nl// &
        'type(dt)::x'//nl//'real::z'//nl//'z=x%y'//nl//'end program'
    do mutation=0,20
        call parse_subset(source,p,d)
        call expect(d%code==0,'default parser baseline')
        call expect(p%nt==1.and.p%derived_types(1)%ncomponents==1,'one component')
        root=p%derived_types(1)%component_initializers(1)
        call expect(root>0,'retained default expression')
        select case(mutation)
        case(1);p%derived_types(1)%component_initializers(1)=0
        case(2);p%derived_types(1)%component_initializers(1)=-1
        case(3);p%derived_types(1)%component_initializers(1)=p%ne+1
        case(4);p%derived_types(1)%component_initializers(2)=root
        case(5);p%derived_types(1)%ncomponents=0
        case(6);p%derived_types(1)%ncomponents=17
        case(7);p%derived_types(1)%module_id=0
        case(8);p%derived_types(1)%component_types(1)=ty_character
        case(9);p%derived_types(1)%component_kinds(1)=16
        case(10);p%expressions(root)%scope=0
        case(11);p%expressions(root)%rank=1;p%expressions(root)%extent=1
        case(12);p%expressions(root)%dims(1)=1
        case(13);p%expressions(root)%constructor_owner=1
        case(14);p%expressions(root)%kind=ex_user_call
        case(15);p%expressions(root)%kind=ex_constructor_index
        case(16);p%expressions(root)%kind=ex_unary;p%expressions(root)%left=root
        case(17);p%expressions(root)%kind=ex_call;p%expressions(root)%op='command_argument_count';allocate(p%expressions(root)%args(0))
        case(18);p%expressions(root)%value%r=ieee_value(0.0_real64,ieee_quiet_nan)
        case(19);p%expressions(root)%value%tag=ty_logical
        case(20);p%expressions(root)%kind=ex_call;p%expressions(root)%op='abs';allocate(p%expressions(root)%args(0))
        end select
        call verify_frontend(source,p,d)
        call expect((d%code==0).eqv.(mutation==0),'adapter independently checks default')
        d=diagnostic_t()
        call execute_program(p,d)
        call expect((d%code==0).eqv.(mutation==0),'runtime fails closed on default mutation')
    end do
    print *, 'PASS derived component defaults assertions:',checks
contains
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok)return
        print *,mutation,label
        if(allocated(d%message))print *,d%message
        error stop 'derived defaults invariant failure'
    end subroutine
end program
