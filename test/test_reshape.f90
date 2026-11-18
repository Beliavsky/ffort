! SPDX-License-Identifier: MIT
program test_reshape
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        'integer::a(2,3)'//nl// &
        'a=reshape(source=[1,2],shape=[2,3],pad=[3,4],order=[2,1])'//nl// &
        'if(sum(a)/=17) error stop 1'//nl//'end program'
    integer::which,j,e,checks,child
    checks=0
    do which=1,23
        call fixture()
        call mutate()
        call verify_frontend(source,p,d)
        call expect((d%code==0).eqv.(which==1),'adapter')
    end do
    do which=1,23
        call fixture()
        call mutate()
        call execute_program(p,d)
        call expect((d%code==0).eqv.(which==1),'runtime')
    end do
    print *, 'PASS: RESHAPE metadata checks:',checks
contains
    subroutine fixture()
        call parse_subset(source,p,d)
        if(d%code/=0) then
            print *,d%message
            error stop 'RESHAPE fixture parse'
        end if
        e=0
        do j=1,p%ne
            if(p%expressions(j)%kind==ex_call.and.p%expressions(j)%op=='reshape') e=j
        end do
        if(e==0) error stop 'RESHAPE fixture IR'
    end subroutine
    subroutine mutate()
        select case(which)
        case(2);p%expressions(e)%rank=1
        case(3);p%expressions(e)%extent=6
        case(4);p%expressions(e)%dims=0
        case(5);p%expressions(e)%typ=ty_real
        case(6);p%expressions(e)%real_kind=8
        case(7);p%expressions(e)%intrinsic_mask=7
        case(8);p%expressions(e)%intrinsic_mask=14
        case(9);p%expressions(e)%intrinsic_mask=31
        case(10);p%expressions(e)%args=p%expressions(e)%args(:1)
        case(11);p%expressions(e)%args=[integer::]
        case(12);deallocate(p%expressions(e)%args)
        case(13);p%expressions(e)%args(1)=e
        case(14);p%expressions(e)%args(2)=0
        case(15);p%expressions(e)%args(3)=p%ne+1
        case(16)
            child=p%expressions(e)%args(1)
            p%expressions(child)%rank=0
        case(17)
            child=p%expressions(e)%args(2)
            p%expressions(child)%typ=ty_real
        case(18)
            child=p%expressions(e)%args(2)
            p%expressions(child)%extent=3
        case(19)
            child=p%expressions(e)%args(3)
            p%expressions(child)%real_kind=8
        case(20)
            child=p%expressions(e)%args(4)
            p%expressions(child)%typ=ty_real
        case(21)
            child=p%expressions(e)%args(4)
            p%expressions(child)%rank=2
        case(22)
            child=p%expressions(e)%args(4)
            p%expressions(child)%extent=1
        case(23)
            child=p%expressions(e)%args(2)
            p%expressions(child)%args(1)=e
        end select
    end subroutine
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok)return
        print *, 'FAIL: RESHAPE ',label,' mutation=',which
        if(allocated(d%message))print *,d%message
        error stop 1
    end subroutine
end program
