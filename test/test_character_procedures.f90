! SPDX-License-Identifier: MIT
program test_character_procedures
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='module m'//nl//'implicit none'//nl//'contains'//nl// &
        'function joined(a,b) result(c)'//nl// &
        'character(*),intent(in)::a(:),b(:)'//nl// &
        'character(len=max(len(a),len(b)))::c(size(a)+size(b))'//nl// &
        'c(:size(a))=a'//nl//'c(size(a)+1:)=b'//nl//'end function'//nl// &
        'end module'//nl//'program test'//nl//'use m'//nl//'implicit none'//nl// &
        'character(2)::a(1)=["ab"]'//nl//'character(4)::b(1)=["cdef"]'//nl// &
        'character(4)::c(2)'//nl//'c=joined(a,b)'//nl// &
        'if(c(1)/="ab  ".or.c(2)/="cdef") error stop 1'//nl// &
        'if(len(c)/=4) error stop 2'//nl//'end program'
    integer::which,q,result,len_expr,lenarg,maxexpr,call_expr
    do which=1,16
        call parse_subset(source,p,d)
        call require_ok('parse')
        result=p%procedures(1)%result_symbol
        maxexpr=p%symbols(result)%length_expr
        len_expr=p%expressions(maxexpr)%args(1)
        lenarg=p%expressions(len_expr)%args(1)
        call_expr=0
        do q=1,p%ne
            if(p%expressions(q)%kind==ex_user_call) call_expr=q
        end do
        if(call_expr==0) error stop 'missing call expression'
        select case(which)
        case(2);p%symbols(result)%character_len=4
        case(3);p%symbols(result)%length_expr=0
        case(4);p%expressions(maxexpr)%op='min'
        case(5);p%expressions(maxexpr)%args=[len_expr,len_expr]
        case(6);p%expressions(len_expr)%op='kind'
        case(7);p%expressions(len_expr)%typ=ty_real
        case(8);p%expressions(len_expr)%rank=1
        case(9);p%expressions(lenarg)%symbol=2
        case(10);p%expressions(call_expr)%character_len=4
        case(11);p%expressions(call_expr)%rank=0
        case(12);p%symbols(1)%character_len=3
        case(13);p%symbols(result)%length_expr=len_expr
        case(14);p%expressions(len_expr)%args=[lenarg,lenarg]
        case(15);p%expressions(maxexpr)%real_kind=8
        case(16);p%symbols(result)%is_parameter=.true.
        end select
        call verify_frontend(source,p,d)
        if(which==1) then
            call require_ok('verify')
            call execute_program(p,d)
            call require_ok('execute')
        else if(d%code==0) then
            print *,which
            error stop 'forged CHARACTER procedure IR passed adapter'
        end if
    end do
    do which=1,10
        call parse_subset(source,p,d)
        call require_ok('runtime parse')
        result=p%procedures(1)%result_symbol
        maxexpr=p%symbols(result)%length_expr
        len_expr=p%expressions(maxexpr)%args(1)
        lenarg=p%expressions(len_expr)%args(1)
        select case(which)
        case(2);p%symbols(result)%length_expr=0
        case(3);p%symbols(result)%length_expr=max_expressions
        case(4);p%expressions(len_expr)%typ=ty_real
        case(5);p%expressions(len_expr)%args=[lenarg,lenarg]
        case(6);p%expressions(len_expr)%args(1)=len_expr
        case(7);p%expressions(len_expr)%real_kind=8
        case(8);p%symbols(result)%character_len=65537
        case(9);p%expressions(maxexpr)%args(1)=maxexpr
        case(10);p%symbols(result)%rank=3
        end select
        call execute_program(p,d)
        if(which==1) then
            call require_ok('runtime baseline')
        else if(d%code/=2) then
            print *,which,d%code
            error stop 'corrupt CHARACTER procedure IR passed runtime'
        end if
    end do
    print '(a)','PASS: CHARACTER procedures, 15 adapter mutations and 9 direct-runtime corruptions'
contains
    subroutine require_ok(label)
        character(*),intent(in)::label
        if(d%code/=0) then
            print *,label,': ',d%message
            error stop 'unexpected CHARACTER procedure failure'
        end if
    end subroutine
end program
