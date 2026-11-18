! SPDX-License-Identifier: MIT
program test_logical_intrinsics
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:evaluate_constant
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    type(value_t)::v
    character(*),parameter::nl=new_line('a')
    character(:),allocatable::source
    character(5)::name
    integer::family,mutation,e,j,checks
    checks=0
    do family=1,5
        select case(family)
        case(1);name='count';source='count([.true.,.false.],kind=8)'
        case(2);name='all';source='all([.true.,.false.],dim=1)'
        case(3);name='any';source='any([.true.,.false.])'
        case(4);name='merge';source='merge(tsource=2_8,mask=.true.,fsource=3_8)'
        case(5);name='dble';source='dble(a=3)'
        end select
        source='program p'//nl//'implicit none'//nl//'print *,'//source//nl//'end program'
        do mutation=0,8
            call parse_subset(source,p,d)
            call expect(d%code==0,'source parses')
            e=0
            do j=1,p%ne
                if(p%expressions(j)%op==name)e=j
            end do
            call expect(e>0,'call exists')
            select case(mutation)
            case(1);p%expressions(e)%typ=ty_character
            case(2);p%expressions(e)%real_kind=16
            case(3);p%expressions(e)%rank=2;p%expressions(e)%extent=-1
            case(4);p%expressions(e)%args(1)=0
            case(5);p%expressions(e)%args=[integer::]
            case(6);p%expressions(e)%args(1)=p%ne+1
            case(7);p%expressions(p%expressions(e)%args(1))%typ=ty_character
            case(8)
                if(family<=3)then
                    p%expressions(e)%intrinsic_mask=8
                else
                    p%expressions(e)%args=[p%expressions(e)%args,p%expressions(e)%args]
                end if
            end select
            call verify_frontend(source,p,d)
            call expect((d%code==0).eqv.(mutation==0),'independent adapter mutation')
            d=diagnostic_t()
            call evaluate_constant(p,e,v,d)
            call expect((d%code==0).eqv.(mutation==0),'runtime mutation')
            if(mutation==0)then
                select case(family)
                case(1);call expect(v%tag==ty_integer.and.v%i==1.and.v%real_kind==8,'COUNT result')
                case(2);call expect(v%tag==ty_logical.and..not.v%l,'ALL result')
                case(3);call expect(v%tag==ty_logical.and.v%l,'ANY result')
                case(4);call expect(v%tag==ty_integer.and.v%i==2.and.v%real_kind==8,'MERGE result')
                case(5);call expect(v%tag==ty_real.and.v%r==3.and.v%real_kind==8,'DBLE result')
                end select
            end if
        end do
    end do
    print *, 'PASS: logical intrinsics adapter/runtime checks:',checks
contains
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok)return
        print *, 'FAIL: ',label,' intrinsic ',name,' mutation ',mutation
        if(allocated(d%message))print *,d%message
        error stop 1
    end subroutine
end program
