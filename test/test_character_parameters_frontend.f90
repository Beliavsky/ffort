! SPDX-License-Identifier: MIT
program test_character_parameters_frontend
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='implicit none'//nl// &
        'character(*),parameter::a=trim("ab  "),b=a//"!",c=""'//nl// &
        'character(*),parameter::v(2)=[character(3)::"x","yz"]'//nl// &
        'character(*),parameter::empty(0)=[character(7)::]'//nl// &
        'character(2)::runtime="ab"'//nl//'integer::i=65'//nl//'print *,char(i,1),achar(i),b,v,runtime,trim(runtime)'//nl//'end'
    integer::which,q,cc,ac,variable,folded_trim,dynamic_trim
    do which=1,22
        call parse_subset(source,p,d)
        call require_ok('baseline parse')
        if(p%symbols(1)%character_len/=2.or.p%symbols(2)%character_len/=3.or. &
           p%symbols(3)%character_len/=0.or.p%symbols(4)%character_len/=3.or. &
           p%symbols(5)%character_len/=7) error stop 'incorrect inferred lengths'
        if(p%symbols(1)%constant_value%s/='ab'.or.p%symbols(2)%constant_value%s/='ab!') &
            error stop 'incorrect scalar parameter cache'
        if(size(p%symbols(4)%constant_values)/=2.or.size(p%symbols(5)%constant_values)/=0) &
            error stop 'incorrect array parameter cache'
        if(p%symbols(4)%constant_values(1)%s/='x  '.or. &
           p%symbols(4)%constant_values(2)%s/='yz ') error stop 'incorrect array values'
        cc=0;ac=0;variable=0;folded_trim=0;dynamic_trim=0
        do q=1,p%ne
            if(p%expressions(q)%kind==ex_call.and.p%expressions(q)%op=='char') cc=q
            if(p%expressions(q)%kind==ex_call.and.p%expressions(q)%op=='achar') ac=q
            if(p%expressions(q)%kind==ex_variable.and.p%expressions(q)%symbol==6) variable=q
            if(p%expressions(q)%kind==ex_call.and.p%expressions(q)%op=='trim') then
                if(p%expressions(q)%character_len>=0) then
                    folded_trim=q
                else
                    dynamic_trim=q
                end if
            end if
        end do
        if(min(folded_trim,dynamic_trim)==0) error stop 'missing folded or dynamic TRIM'
        if(p%expressions(folded_trim)%character_len/=2) error stop 'wrong folded TRIM length'
        if(min(cc,ac,variable)==0) error stop 'missing intrinsic expression'
        select case(which)
        case(2);p%symbols(1)%character_len=3
        case(3);p%symbols(1)%initializer_expr=0
        case(4);p%symbols(1)%initializer_expr=variable
        case(5);p%symbols(2)%constant_value%s='xxx'
        case(6);p%symbols(4)%constant_values(1)%s='bad'
        case(7);p%symbols(5)%character_len=0
        case(8);p%expressions(cc)%typ=ty_integer
        case(9);p%expressions(cc)%rank=1
        case(10);p%expressions(cc)%character_len=2
        case(11);p%expressions(cc)%real_kind=8
        case(12);p%expressions(ac)%typ=ty_real
        case(13);p%expressions(ac)%rank=2
        case(14);p%expressions(ac)%character_len=0
        case(15);p%expressions(ac)%real_kind=8
        case(16);p%expressions(cc)%args(1)=0
        case(17);p%expressions(cc)%args(2)=p%expressions(cc)%args(1)
        case(18);p%symbols(4)%initializer_expr=0
        case(19);p%symbols(4)%character_len=2
        case(20);p%symbols(3)%constant_value%s=' '
        case(21);p%expressions(folded_trim)%character_len=3
        case(22);p%expressions(dynamic_trim)%character_len=2
        end select
        call verify_frontend(source,p,d)
        if(which==1) then
            call require_ok('baseline verification')
        else if(d%code==0) then
            print *,which
            error stop 'forged CHARACTER PARAMETER/CHAR IR admitted'
        end if
    end do
    print '(a)','PASS: inferred lengths/caches and 21 adapter mutation rejections'
contains
    subroutine require_ok(label)
        character(*),intent(in)::label
        if(d%code/=0) then
            print *,label,': ',d%message
            error stop 'unexpected failure'
        end if
    end subroutine
end program
