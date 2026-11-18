! SPDX-License-Identifier: MIT
program test_character_substrings
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program t'//nl//'implicit none'//nl// &
        'character(4)::s'//nl//'integer::i,j'//nl// &
        "s='abcd'"//nl//'i=2'//nl//'j=3'//nl// &
        "s(i:j)='X'"//nl//"if(s/='aX d') error stop 1"//nl// &
        "if(s(i:j)/='X ') error stop 2"//nl//'end program'
    integer::mode,which,q,sub,lo,hi,target
    do mode=1,2
        do which=1,17
            call parse_subset(source,p,d)
            call require_ok('parse')
            sub=0;target=0
            do q=1,p%nc
                if(p%code(q)%op==op_assign.and.p%code(q)%c/=0) then
                    sub=p%code(q)%c;target=q;exit
                end if
            end do
            if(sub==0) error stop 'substring target absent'
            lo=p%expressions(sub)%left;hi=p%expressions(sub)%right
            select case(which)
            case(2);p%expressions(sub)%typ=ty_integer
            case(3);p%expressions(sub)%rank=1
            case(4);p%expressions(sub)%symbol=0
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
            case(17);p%code(target)%d=lo
            end select
            if(mode==1) then
                call verify_frontend(source,p,d)
            else
                call execute_program(p,d)
            end if
            if(which==1) then
                call require_ok('baseline')
            else if(d%code==0) then
                print *,mode,which
                error stop 'forged substring metadata was accepted'
            else if(mode==2.and.d%code/=2) then
                print *,mode,which,d%code
                error stop 'substring runtime failure had wrong code'
            end if
        end do
    end do
    print '(a)','PASS: scalar substrings, 16 adapter mutations and 16 direct-runtime corruptions'
contains
    subroutine require_ok(label)
        character(*),intent(in)::label
        if(d%code/=0) then
            print *,label,': ',d%message
            error stop 'unexpected substring failure'
        end if
    end subroutine
end program
