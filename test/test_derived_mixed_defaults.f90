! SPDX-License-Identifier: MIT
program test_derived_mixed_defaults
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(:),allocatable::source
    integer::mutation,roots(4),checks
    checks=0
    source='module types'//nl//'implicit none'//nl//'type::dt'//nl// &
        'integer::a,b=8,c,d=10'//nl//'end type'//nl//'end module'//nl// &
        'program main'//nl//'use types'//nl//'implicit none'//nl// &
        'type(dt)::x'//nl//'if(x%b/=8.or.x%d/=10)error stop 1'//nl// &
        'x%a=1'//nl//'x%c=3'//nl//'if(x%a/=1.or.x%c/=3)error stop 1'//nl//'end program'
    do mutation=0,8
        call parse_subset(source,p,d)
        call expect(d%code==0,'parse mixed declaration')
        roots=p%derived_types(1)%component_initializers(1:4)
        call expect(roots(1)==0.and.roots(3)==0,'undefined entities have no defaults')
        call expect(roots(2)>0.and.roots(4)>0.and.roots(2)/=roots(4),'distinct initializer roots')
        select case(mutation)
        case(1);p%derived_types(1)%component_initializers(1)=roots(2)
        case(2);p%derived_types(1)%component_initializers(2)=0
        case(3);p%derived_types(1)%component_initializers(3)=roots(4)
        case(4);p%derived_types(1)%component_initializers(4)=0
        case(5);p%derived_types(1)%component_initializers(2)=roots(4)
        case(6);p%derived_types(1)%component_initializers(4)=roots(2)
        case(7);p%derived_types(1)%component_initializers(2)=p%ne+1
        case(8);p%derived_types(1)%component_initializers(4)=-1
        end select
        call verify_frontend(source,p,d)
        call expect((d%code==0).eqv.(mutation==0),'adapter binds each initializer independently')
        if(mutation==0.or.mutation>=7)then
            d=diagnostic_t()
            call execute_program(p,d)
            call expect((d%code==0).eqv.(mutation==0),'runtime validates default roots')
        end if
    end do
    print *, 'PASS grouped derived defaults assertions:',checks
contains
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok)return
        print *,mutation,label
        if(allocated(d%message))print *,d%message
        error stop 'grouped derived defaults failure'
    end subroutine
end program
