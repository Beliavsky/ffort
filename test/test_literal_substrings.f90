! SPDX-License-Identifier: MIT
program test_literal_substrings
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(:),allocatable::source
    integer::mode,which,q,sub,lo,hi,variant,nchecks
    nchecks=0
    do variant=1,3
        source='program t'//nl//'implicit none'//nl// &
            'character(4)::s'//nl//'integer::i,j'//nl//'i=2'//nl//'j=3'//nl
        select case(variant)
        case(1)
            source=source//"s='abcd'(i:j)"//nl//"if(s/='bc') error stop 1"//nl
        case(2)
            source=source//"if(kind('abcd'(i:j))/=1) error stop 1"//nl
        case(3)
            source=source//"if(len('abcd'(i:j))/=2) error stop 1"//nl
        end select
        source=source//'end program'
        do mode=1,2
            do which=1,29
                call parse_subset(source,p,d)
                call require_ok('parse')
                sub=0
                do q=1,p%ne
                    if(p%expressions(q)%kind==ex_substring) then
                        sub=q;exit
                    end if
                end do
                if(sub==0) error stop 'literal substring absent'
                lo=p%expressions(sub)%left;hi=p%expressions(sub)%right
                select case(which)
                case(2);p%expressions(sub)%typ=ty_integer
                case(3);p%expressions(sub)%rank=1
                case(4);p%expressions(sub)%symbol=1
                case(5);p%expressions(sub)%character_len=2
                case(6);p%expressions(sub)%stride=lo
                case(7);p%expressions(sub)%left2=lo
                case(8);p%expressions(sub)%right2=hi
                case(9);p%expressions(sub)%stride2=lo
                case(10);p%expressions(sub)%left=max_expressions
                case(11);p%expressions(sub)%right=sub
                case(12);p%expressions(sub)%real_kind=8
                case(13);p%expressions(sub)%extent=1
                case(14);p%expressions(sub)%dims(1)=1
                case(15);p%expressions(sub)%length_expr=lo
                case(16);p%expressions(sub)%args=[lo,hi]
                case(17);p%expressions(sub)%value%tag=ty_integer
                case(18);p%expressions(sub)%value%real_kind=8
                case(19);deallocate(p%expressions(sub)%value%s)
                case(20);p%expressions(sub)%value%s=repeat('a',65537)
                case(21);p%expressions(sub)%third=lo
                case(22);p%expressions(sub)%left3=lo
                case(23);p%expressions(sub)%right3=hi
                case(24);p%expressions(sub)%stride3=lo
                case(25);p%expressions(sub)%triplet(2)=.true.
                case(26);p%expressions(sub)%triplet(3)=.true.
                case(27);p%expressions(sub)%symbol=-1
                case(28);p%expressions(lo)%typ=ty_real
                case(29);p%expressions(lo)%rank=1
                end select
                if(mode==1) then
                    call verify_frontend(source,p,d)
                else
                    call execute_program(p,d)
                end if
                if(which==1) then
                    call require_ok('baseline')
                else if(d%code==0) then
                    print *,variant,mode,which
                    error stop 'forged literal substring accepted'
                else if(mode==2.and.d%code/=2) then
                    print *,variant,mode,which,d%code
                    error stop 'runtime failure had wrong code'
                end if
                nchecks=nchecks+1
            end do
        end do
    end do
    ! Changing the literal value is a valid new IR program, but must not match
    ! the original source during independent adapter verification.
    call parse_subset(source,p,d)
    call require_ok('value mutation parse')
    p%expressions(sub)%value%s='wxyz'
    call verify_frontend(source,p,d)
    if(d%code==0) error stop 'changed literal value passed adapter'
    call parse_subset(source,p,d)
    call require_ok('length mutation parse')
    p%expressions(sub)%value%s='abcd '
    call verify_frontend(source,p,d)
    if(d%code==0) error stop 'padded literal value passed adapter'
    print '(a,i0,a)','PASS: literal substrings, ',nchecks+2,' adapter/runtime checks'
contains
    subroutine require_ok(label)
        character(*),intent(in)::label
        if(d%code/=0) then
            print *,label,': ',d%message
            error stop 'unexpected literal substring failure'
        end if
    end subroutine
end program
