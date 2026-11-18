! SPDX-License-Identifier: MIT
program test_select_case_frontend
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        'integer,parameter :: a(3)=[-1,0,2]'//nl// &
        'character(len=4)::c'//nl//'integer::i'//nl// &
        "c='xy'"//nl//'i=a(2)'//nl//'select case(i)'//nl// &
        'case(:-1)'//nl//'print *,1'//nl//'case default'//nl//'print *,2'//nl// &
        'case(0,2:4)'//nl//'print *,3'//nl//'end select'//nl// &
        'select case(trim(c))'//nl//"case('xy')"//nl//'print *,4'//nl// &
        'end select'//nl//'end program'
    integer::which,e,c,s,k,q
    do which=1,23
        call parse_subset(source,p,d)
        call require_ok('baseline parse')
        c=find_instruction(op_select);k=find_instruction(op_case)
        s=1;e=p%code(c)%a
        select case(which)
        case(2);p%code(c)%a=0
        case(3);p%code(c)%target=c
        case(4);p%code(k)%a=0
        case(5);p%code(k)%target=k
        case(6);p%code(k)%items=[0,0]
        case(7);p%code(k)%items=[0]
        case(8);deallocate(p%code(k)%items)
        case(9);p%code(k)%items=[p%code(k)%items,p%code(k)%items]
        case(10);p%code(p%code(k)%target-1)%target=c
        case(11);p%code(p%code(k)%target-1)%op=op_return
        case(12);p%symbols(s)%constant_values(1)%i=99
        case(13);p%symbols(s)%constant_values=p%symbols(s)%constant_values(:2)
        case(14);deallocate(p%symbols(s)%constant_values)
        case(15);p%symbols(s)%parameter_ready=.false.
        case(16);p%symbols(2)%character_len=3
        case(17);p%symbols(2)%length_expr=0
        case(18);p%expressions(p%symbols(2)%length_expr)%value%i=7
        case(19:23)
            do q=1,p%ne
                if(p%expressions(q)%kind==ex_call.and.p%expressions(q)%op=='trim') exit
            end do
            select case(which)
            case(19);p%expressions(q)%rank=1
            case(20);p%expressions(q)%typ=ty_integer
            case(21);p%expressions(q)%args=[p%expressions(q)%args,p%expressions(q)%args]
            case(22);p%expressions(q)%args(1)=0
            case(23);p%expressions(q)%args(1)=q
            end select
        end select
        call verify_frontend(source,p,d)
        if(which==1) then
            call require_ok('baseline verification')
        else if(d%code==0) then
            print *,which
            error stop 'forged SELECT/character/parameter IR admitted'
        end if
    end do
    print '(a)','PASS: SELECT baseline and 22 adapter disagreements'
contains
    integer function find_instruction(op) result(c)
        integer,intent(in)::op
        do c=1,p%nc
            if(p%code(c)%op==op) return
        end do
        error stop 'test instruction absent'
    end function
    subroutine require_ok(label)
        character(*),intent(in)::label
        if(d%code/=0) then
            print *,label,': ',d%message
            error stop 'unexpected failure'
        end if
    end subroutine
end program
