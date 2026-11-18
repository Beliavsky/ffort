! SPDX-License-Identifier: MIT
program test_argument_frontend
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    implicit none
    type(program_t) :: p
    type(diagnostic_t) :: d
    character(*), parameter :: nl=new_line('a')
    character(*), parameter :: source='program main'//nl// &
        'implicit none'//nl//'integer :: a(-2:2),b'//nl//'a=3'//nl// &
        'call change(a(2:-2:-2),b)'//nl//'print *,inspect(a),b'//nl//'contains'//nl// &
        'subroutine change(x,y)'//nl//'integer,intent(inout)::x(0:)'//nl// &
        'integer,intent(out)::y'//nl//'x=x+1'//nl// &
        'y=size(x)+lbound(x,1)+ubound(x,1)'//nl//'end subroutine'//nl// &
        'integer function inspect(x) result(r)'//nl//'integer,intent(in)::x(:)'//nl// &
        'r=size(x,1)'//nl//'end function'//nl//'end program'
    integer :: which,i,array_dummy,scalar_dummy,in_dummy,callpc,actual,inquiry,array_expr
    do which=1,16
        call parse_subset(source,p,d)
        if(d%code/=0) then
            print *,d%line,d%message
            error stop 'argument frontend fixture parse failed'
        end if
        array_dummy=p%procedures(1)%args(1)
        scalar_dummy=p%procedures(1)%args(2)
        in_dummy=p%procedures(2)%args(1)
        callpc=0;inquiry=0;array_expr=0
        do i=1,p%nc
            if(p%code(i)%op==op_call) callpc=i
        end do
        do i=1,p%ne
            if(p%expressions(i)%kind==ex_call.and.p%expressions(i)%op=='size') inquiry=i
            if(p%expressions(i)%kind==ex_variable.and.p%expressions(i)%symbol==array_dummy) array_expr=i
        end do
        actual=p%code(callpc)%items(1)
        if(min(callpc,inquiry,array_expr,actual)==0) error stop 'missing argument test fixture node'
        select case(which)
        case(2);p%symbols(array_dummy)%dummy_intent=1
        case(3);p%symbols(scalar_dummy)%dummy_intent=3
        case(4);p%symbols(in_dummy)%dummy_intent=2
        case(5);p%symbols(array_dummy)%assumed_shape=.false.
        case(6);p%symbols(array_dummy)%lower_bound=2
        case(7);p%symbols(array_dummy)%rank=0
        case(8);p%expressions(actual)%parenthesized=.true.
        case(9);p%expressions(actual)%rank=0
        case(10);p%expressions(inquiry)%rank=1
        case(11);p%expressions(inquiry)%typ=ty_real
        case(12);p%expressions(array_expr)%extent=3
        case(13);p%expressions(p%code(callpc)%items(2))%parenthesized=.true.
        case(14);p%symbols(array_dummy)%lower_expr=0
        case(15);p%symbols(scalar_dummy)%is_parameter=.true.
        case(16);p%symbols(array_dummy)%dummy_intent=0
        end select
        call verify_frontend(source,p,d)
        if((d%code==0).neqv.(which==1)) then
            print *,which
            if(allocated(d%message)) print *,d%line,d%message
            error stop 'argument frontend invariant regression'
        end if
    end do
    print '(a)','PASS: argument frontend baseline and 15 independent AST/IR mutation rejections'
end program
