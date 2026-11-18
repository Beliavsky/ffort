! SPDX-License-Identifier: MIT
program test_character_arrays_frontend
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='implicit none'//nl// &
        'integer,parameter::n=3'//nl// &
        'character(n),parameter::a(2)=[character(n)::"a","bc"]'//nl// &
        'character(n)::b(2)=["abc","def"]'//nl// &
        'b=b(2:1:-1)'//nl//'print *,"!"//a,b,a==b'//nl//'end'
    integer::which,q,ctor,concat,lit,variable
    do which=1,18
        call parse_subset(source,p,d)
        call require_ok('baseline parse')
        ctor=0;concat=0;lit=0;variable=0
        do q=1,p%ne
            if(p%expressions(q)%kind==ex_constructor.and.p%expressions(q)%op=='character') ctor=q
            if(p%expressions(q)%kind==ex_binary.and.p%expressions(q)%op=='//') concat=q
            if(p%expressions(q)%kind==ex_literal.and.p%expressions(q)%typ==ty_character) lit=q
            if(p%expressions(q)%kind==ex_variable.and.p%expressions(q)%typ==ty_character) variable=q
        end do
        if(min(ctor,concat,lit,variable)==0) error stop 'missing test expression'
        select case(which)
        case(2);p%expressions(ctor)%character_len=2
        case(3);p%expressions(ctor)%length_expr=0
        case(4);p%expressions(ctor)%op=''
        case(5);p%expressions(ctor)%typ=ty_integer
        case(6);p%expressions(ctor)%rank=0
        case(7);p%expressions(ctor)%args=[p%expressions(ctor)%args,lit]
        case(8);p%expressions(concat)%character_len=1
        case(9);p%expressions(concat)%typ=ty_logical
        case(10);p%expressions(concat)%op='+'
        case(11);p%expressions(lit)%character_len=8
        case(12);p%expressions(variable)%character_len=8
        case(13);p%symbols(2)%constant_values(1)%s='a'
        case(14);p%symbols(2)%constant_values(2)%s='xx '
        case(15);p%symbols(2)%character_len=4
        case(16);p%symbols(2)%length_expr=0
        case(17);p%expressions(p%symbols(2)%length_expr)%symbol=2
        case(18);p%expressions(ctor)%extent=1
        end select
        call verify_frontend(source,p,d)
        if(which==1) then
            call require_ok('baseline verification')
        else if(d%code==0) then
            print *,which
            error stop 'forged CHARACTER array IR admitted'
        end if
    end do
    print '(a)','PASS: CHARACTER arrays and 17 adapter mutation rejections'
contains
    subroutine require_ok(label)
        character(*),intent(in)::label
        if(d%code/=0) then
            print *,label,': ',d%message
            error stop 'unexpected failure'
        end if
    end subroutine
end program
