! SPDX-License-Identifier: MIT
program test_array_actual_frontend
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='module m'//nl//'implicit none'//nl// &
        'integer,parameter::dp=kind(1d0)'//nl//'contains'//nl// &
        'function mean(x) result(y)'//nl//'real(dp),intent(in)::x(:)'//nl// &
        'real(dp)::y'//nl//'y=sum(x)/size(x)'//nl//'end function'//nl// &
        'end module'//nl//'program p'//nl//'use m'//nl//'implicit none'//nl// &
        'real(dp)::x(4)=[1d0,2d0,3d0,4d0]'//nl// &
        'print *,mean(x**2)'//nl//'end program'
    integer::which,e
    do which=1,10
        call parse_subset(source,p,d)
        if(d%code/=0) error stop 'array expression actual baseline parse failed'
        do e=1,p%ne
            if(p%expressions(e)%op=='**') exit
        end do
        if(e>p%ne) error stop 'array power test expression absent'
        select case(which)
        case(2);p%expressions(e)%rank=0
        case(3);p%expressions(e)%real_kind=4
        case(4);p%expressions(e)%typ=ty_integer
        case(5);p%expressions(e)%extent=3
        case(6);p%expressions(e)%dims(1)=3
        case(7);p%expressions(e)%op='*'
        case(8);p%expressions(e)%left=0
        case(9);p%expressions(e)%right=0
        case(10);p%expressions(e)%rank=2
        end select
        call verify_frontend(source,p,d)
        if((d%code==0).neqv.(which==1)) then
            print *,which
            if(allocated(d%message)) print *,d%message
            error stop 'array actual AST/IR disagreement admitted'
        end if
    end do
    print '(a)','PASS: array actual baseline and nine AST/IR mutation rejections'
end program
