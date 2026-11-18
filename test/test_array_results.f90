! SPDX-License-Identifier: MIT
program test_array_results
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='module m'//nl//'implicit none'//nl//'contains'//nl// &
        'pure function vector(x) result(y)'//nl//'integer,intent(in)::x'//nl// &
        'integer::y(2)'//nl//'y=[x,x+1]'//nl//'end function'//nl//'end module'//nl// &
        'program main'//nl//'use m'//nl//'implicit none'//nl//'integer::a(2)'//nl// &
        'a=vector(3)'//nl//'if(sum(a)/=7) error stop 1'//nl//'end program'
    integer::which,j,call_expr,result_sym,checks
    checks=0
    do which=1,11
        call fixture()
        call mutate()
        call verify_frontend(source,p,d)
        call expect((d%code==0).eqv.(which==1),'array-result adapter mutation')
    end do
    do which=1,11
        call fixture()
        call mutate()
        call execute_program(p,d)
        call expect((d%code==0).eqv.(which==1),'array-result runtime mutation')
    end do
    print *, 'PASS: array-result mutation checks:',checks
contains
    subroutine fixture()
        call parse_subset(source,p,d)
        if(d%code/=0) then
            print *,d%message
            error stop 'array-result fixture parse'
        end if
        call_expr=0
        do j=1,p%ne
            if(p%expressions(j)%kind==ex_user_call) call_expr=j
        end do
        if(call_expr==0) error stop 'array-result fixture IR'
        result_sym=p%procedures(1)%result_symbol
    end subroutine
    subroutine mutate()
        select case(which)
        case(2);p%expressions(call_expr)%rank=2;p%expressions(call_expr)%dims=-1
        case(3);p%expressions(call_expr)%extent=2
        case(4);p%expressions(call_expr)%typ=ty_real
        case(5);p%expressions(call_expr)%real_kind=8
        case(6);p%procedures(1)%result_symbol=p%ns+1
        case(7);p%symbols(result_sym)%scope=0
        case(8);p%symbols(result_sym)%is_dummy=.true.
        case(9);p%symbols(result_sym)%rank=0
        case(10);p%procedures(1)%is_elemental=.true.
        case(11);p%expressions(call_expr)%args=[integer::]
        end select
    end subroutine
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok)return
        print *, 'FAIL: ',label,' mutation=',which
        if(allocated(d%message))print *,d%message
        error stop 1
    end subroutine
end program
