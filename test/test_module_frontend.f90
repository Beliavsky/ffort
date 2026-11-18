! SPDX-License-Identifier: MIT
program test_module_frontend
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='module m'//nl//'implicit none'//nl//'contains'//nl// &
        'function twice(x) result(y)'//nl//'real, intent(in) :: x'//nl//'real :: y'//nl// &
        'y=2*x'//nl//'end function twice'//nl//'end module m'//nl// &
        'program main'//nl//'use m'//nl//'real :: x,y'//nl//'x=2.3'//nl//'y=twice(x)'//nl//'end program main'
    character(*),parameter::forward_source='module a'//nl//'contains'//nl// &
        'function count(x) result(y)'//nl//'integer,intent(in)::x'//nl//'integer::y'//nl// &
        'y=twice(x)'//nl//'end function'//nl// &
        'function twice(x) result(y)'//nl//'integer,intent(in)::x'//nl// &
        'integer,parameter::factor=2'//nl//'integer::y'//nl//'y=factor*x'//nl// &
        'end function'//nl//'end module'//nl// &
        'module b'//nl//'contains'//nl//'function twice(x) result(y)'//nl// &
        'integer,intent(in)::x'//nl//'integer::y'//nl//'y=3*x'//nl// &
        'end function'//nl//'end module'//nl// &
        'program main'//nl//'use a'//nl//'print*,count(2)'//nl//'end program'
    integer::which,e,s
    do which=1,25
        call parse_subset(source,p,d)
        if(d%code/=0) then
            print *,d%message
            error stop 'module frontend fixture parse failed'
        end if
        e=p%code(p%nc)%a;s=p%procedures(1)%args(1)
        select case(which)
        case(2);p%procedures(1)%name='other'
        case(3);p%procedures(1)%module_name='other'
        case(4);p%procedures(1)%args=[integer::]
        case(5);p%procedures(1)%result_symbol=s
        case(6);p%symbols(s)%is_dummy=.false.
        case(7);p%symbols(s)%scope=0
        case(8);p%symbols(s)%typ=ty_integer
        case(9);p%expressions(e)%typ=ty_integer
        case(10);p%expressions(e)%rank=1
        case(11);p%expressions(e)%symbol=2
        case(12);p%expressions(e)%scope=1
        case(13);p%entry_pc=1
        case(14);p%uses(1)=0
        case(15);p%use_lines(1)=1
        case(16);p%code(1)%scope=0
        case(17);p%procedures(1)%last=p%procedures(1)%first-1
        case(18);p%procedures(1)%result_symbol=p%ns+1
        case(19);p%procedures(1)%args(1)=0
        case(20);p%expressions(e)%args(1)=p%ne+1
        case(21);deallocate(p%expressions(e)%args)
        case(22);deallocate(p%procedures(1)%args)
        case(23);deallocate(p%procedures)
        case(24);deallocate(p%symbols)
        case(25);p%np=max_procedures+1
        end select
        call verify_frontend(source,p,d)
        if((d%code==0).neqv.(which==1)) then
            print *,which
            if(allocated(d%message)) print *,d%message
            error stop 'module frontend invariant regression'
        end if
    end do
    do which=1,2
        call parse_subset(forward_source,p,d)
        if(d%code/=0) then
            print *,d%message
            error stop 'module forward fixture parse failed'
        end if
        ! Same-named, identically typed functions in different modules must
        ! never be interchangeable, even when the shape cache still agrees.
        if(which==2) then
            e=p%code(p%procedures(1)%first)%a
            p%expressions(e)%symbol=3
        end if
        call verify_frontend(forward_source,p,d)
        if((d%code==0).neqv.(which==1)) then
            if(allocated(d%message)) print *,d%message
            error stop 'module forward binding regression'
        end if
    end do
    print '(a)','PASS: 2 module frontend baselines and 25 independent IR mutation rejections' 
end program
