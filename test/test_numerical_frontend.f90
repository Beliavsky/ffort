! SPDX-License-Identifier: MIT
program test_numerical_frontend
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='module m'//nl// &
        'use, intrinsic :: iso_fortran_env, only: real64'//nl// &
        'implicit none'//nl//'private'//nl//'integer,parameter,public::dp=real64'//nl// &
        'public::twice,show'//nl//'contains'//nl// &
        'pure real(dp) function twice(x) result(y)'//nl// &
        'real(dp),intent(in)::x'//nl//'y=2.0_dp*x'//nl// &
        'if(x<0.0_dp) return'//nl//'y=y+1.0_dp'//nl//'end function'//nl// &
        'subroutine show(text,x)'//nl//'character(len=*),intent(in)::text'//nl// &
        'real(dp),intent(in)::x'//nl//'print ''(a,f10.3)'',text,x'//nl// &
        'if(x<0.0_dp.or.x>10.0_dp) error stop ''range'''//nl//'end subroutine'//nl// &
        'end module'//nl//'program main'//nl//'use m,only:dp,twice,show'//nl// &
        'real(dp),parameter::input=2.0_dp'//nl//'call local(''value'')'//nl//'contains'//nl// &
        'subroutine local(text)'//nl//'character(len=*),intent(in)::text'//nl// &
        'call show(text,twice(input))'//nl//'return'//nl//'end subroutine'//nl//'end program'
    integer::which,i,lit,bin,callpc,printpc,stoppc,retpc,constant,imported,result_symbol,dummy
    do which=1,30
        call parse_subset(source,p,d)
        if(d%code/=0) then
            print *,d%line,d%message
            error stop 'numerical frontend fixture parse failed'
        end if
        lit=0;bin=0;callpc=0;printpc=0;stoppc=0;retpc=0;constant=0;imported=0
        do i=1,p%ne
            if(p%expressions(i)%kind==ex_literal.and.p%expressions(i)%typ==ty_real) lit=i
            if(p%expressions(i)%kind==ex_binary.and.p%expressions(i)%typ==ty_real) bin=i
        end do
        do i=1,p%nc
            if(p%code(i)%op==op_call) callpc=i
            if(p%code(i)%op==op_print) printpc=i
            if(p%code(i)%op==op_error_stop) stoppc=i
            if(p%code(i)%op==op_return) retpc=i
        end do
        do i=1,p%ns
            if(p%symbols(i)%name=='input') constant=i
            if(p%symbols(i)%is_intrinsic) imported=i
        end do
        result_symbol=p%procedures(1)%result_symbol;dummy=p%procedures(1)%args(1)
        select case(which)
        case(2);p%procedures(1)%is_pure=.false.
        case(3);p%procedures(1)%is_public=.false.
        case(4);p%module_private(1)=.false.
        case(5);p%use_only(1)=.false.
        case(6);p%only_names(1,1)='other'
        case(7);p%n_only(1)=65
        case(8);p%symbols(imported)%constant_value%i=4
        case(9);p%symbols(imported)%is_intrinsic=.false.
        case(10);p%symbols(imported)%scope=0
        case(11);p%symbols(result_symbol)%real_kind=4
        case(12);p%symbols(dummy)%real_kind=4
        case(13);p%symbols(constant)%constant_value%real_kind=4
        case(14);p%expressions(lit)%real_kind=4
        case(15);p%expressions(lit)%value%real_kind=4
        case(16);p%expressions(bin)%real_kind=4
        case(17);p%code(callpc)%symbol=1
        case(18);p%code(callpc)%items=[integer::]
        case(19);deallocate(p%code(callpc)%items)
        case(20);p%code(callpc)%items(1)=p%ne+1
        case(21);p%code(printpc)%format='(a,f11.3)'
        case(22);deallocate(p%code(printpc)%format)
        case(23);p%code(printpc)%items=[integer::]
        case(24);p%expressions(p%code(stoppc)%a)%value%s='wrong'
        case(25);p%code(stoppc)%a=0
        case(26);p%code(retpc)%op=op_jump
        case(27);p%procedures(3)%module_id=1
        case(28);p%procedures(2)%is_subroutine=.false.
        case(29);p%procedures(3)%result_symbol=constant
        case(30);p%symbols(constant)%is_intrinsic=.true.
        end select
        call verify_frontend(source,p,d)
        if((d%code==0).neqv.(which==1)) then
            print *,which
            if(allocated(d%message)) print *,d%line,d%message
            error stop 'numerical frontend invariant regression'
        end if
    end do
    print '(a)','PASS: numerical frontend baseline and 29 independent AST/IR mutation rejections'
end program
