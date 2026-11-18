! SPDX-License-Identifier: MIT
program test_parity_intrinsic
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:evaluate_constant,execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    type(value_t)::v
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        'print *,parity([.true.,.false.,.true.],dim=1)'//nl//'end program'
    integer::mutation,e,a,j,checks
    checks=0
    do mutation=0,13
        call parse_subset(source,p,d)
        call expect(d%code==0,'source parses')
        e=0
        do j=1,p%ne
            if(p%expressions(j)%op=='parity')e=j
        end do
        call expect(e>0,'call exists');a=p%expressions(e)%args(1)
        select case(mutation)
        case(1);p%expressions(e)%typ=ty_integer
        case(2);p%expressions(e)%real_kind=8
        case(3);p%expressions(e)%rank=1;p%expressions(e)%extent=-1
        case(4);p%expressions(e)%args(1)=0
        case(5);p%expressions(e)%args=[integer::]
        case(6);p%expressions(e)%args(1)=p%ne+1
        case(7);p%expressions(a)%typ=ty_integer
        case(8);p%expressions(e)%intrinsic_mask=8
        case(9);p%expressions(e)%intrinsic_mask=7
        case(10);p%expressions(e)%scope=999
        case(11);p%expressions(a)%real_kind=8
        case(12);p%expressions(e)%args(1)=e
        case(13);p%expressions(p%expressions(e)%args(2))%typ=ty_real
        end select
        call verify_frontend(source,p,d)
        call expect((d%code==0).eqv.(mutation==0),'adapter result')
        d=diagnostic_t()
        if(mutation==10)then
            ! Constant evaluation intentionally has no active procedure frame.
            call execute_program(p,d)
        else
            call evaluate_constant(p,e,v,d)
        end if
        call expect((d%code==0).eqv.(mutation==0),'runtime result')
        if(mutation==0)call expect(v%tag==ty_logical.and.v%real_kind==4.and..not.v%l,'even parity')
    end do
    print *, 'PASS: PARITY independent adapter/runtime mutation checks:',checks
contains
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok)return
        print *, 'FAIL: ',label,' mutation ',mutation
        if(allocated(d%message))print *,d%message
        error stop 1
    end subroutine
end program
