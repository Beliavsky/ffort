! SPDX-License-Identifier: MIT
program test_character_parameters_runtime
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_runtime,only:execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='implicit none'//nl// &
        'integer::i=65,j(2)=[66,67]'//nl// &
        'character(1)::s,a(2)'//nl// &
        's=char(i,1)'//nl//'a=achar(j)'//nl// &
        'if(s/="A") error stop 1'//nl// &
        'if(any(a/=["B","C"])) error stop 2'//nl//'end'
    integer::which,q,cc,ac,arg,karg
    do which=1,19
        call parse_subset(source,p,d)
        if(d%code/=0) then
            print *,d%message
            error stop 'CHAR runtime baseline parse'
        end if
        cc=0;ac=0
        do q=1,p%ne
            if(p%expressions(q)%kind==ex_call.and.p%expressions(q)%op=='char') cc=q
            if(p%expressions(q)%kind==ex_call.and.p%expressions(q)%op=='achar') ac=q
        end do
        if(min(cc,ac)==0) error stop 'missing intrinsic expression'
        arg=p%expressions(cc)%args(1);karg=p%expressions(cc)%args(2)
        select case(which)
        case(2);p%expressions(cc)%typ=ty_integer
        case(3);p%expressions(cc)%character_len=2
        case(4);p%expressions(cc)%real_kind=8
        case(5);p%expressions(cc)%rank=1
        case(6);p%expressions(ac)%typ=ty_logical
        case(7);p%expressions(ac)%character_len=0
        case(8);p%expressions(ac)%real_kind=8
        case(9);p%expressions(ac)%rank=0
        case(10);p%expressions(ac)%rank=2
        case(11);p%expressions(cc)%args(1)=0
        case(12);p%expressions(cc)%args(1)=cc
        case(13);deallocate(p%expressions(cc)%args)
        case(14);p%expressions(cc)%args=[arg,karg,karg]
        case(15);p%expressions(karg)%value%i=4
        case(16);p%expressions(karg)%typ=ty_real
        case(17);p%expressions(arg)%typ=ty_real
        case(18);p%expressions(arg)%real_kind=2
        case(19);p%expressions(ac)%extent=3
        end select
        call execute_program(p,d)
        if(which==1) then
            if(d%code/=0) then
                print *,d%message
                error stop 'CHAR runtime baseline failed'
            end if
        else if(d%code/=2) then
            print *,which,d%code
            error stop 'corrupt CHAR/ACHAR IR accepted'
        end if
    end do
    print '(a)','PASS: CHAR/ACHAR values and 18 runtime corruption rejections'
end program
