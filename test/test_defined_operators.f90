! SPDX-License-Identifier: MIT
program test_defined_operators
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fortfront_compiler, only: compiler_frontend_result_t,compiler_frontend_options_t, &
        compile_frontend_from_string,INPUT_MODE_STANDARD,OPERATING_MODE_STRICT, &
        query_resolved_type,resolved_type_query_t,TREAL,TLOGICAL
    use fortfront_ast, only: binary_op_node
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source= &
        'module ops'//nl// &
        'implicit none'//nl// &
        'private'//nl// &
        'public::operator(.in.),operator(.twice.)'//nl// &
        'interface operator(.in.)'//nl// &
        'module procedure member'//nl// &
        'end interface'//nl// &
        'interface operator(.twice.)'//nl// &
        'module procedure twice'//nl// &
        'end interface'//nl// &
        'contains'//nl// &
        'pure logical function member(x,a) result(y)'//nl// &
        'integer,intent(in)::x,a(:)'//nl// &
        'integer::j'//nl// &
        'y=.false.'//nl// &
        'do j=1,size(a)'//nl// &
        'y=y.or.x==a(j)'//nl// &
        'end do'//nl// &
        'end function'//nl// &
        'pure elemental real(kind=8) function twice(x) result(y)'//nl// &
        'real(kind=8),intent(in)::x'//nl// &
        'y=2*x'//nl// &
        'end function'//nl// &
        'end module'//nl// &
        'program main'//nl// &
        'use ops, only:operator(.in.),operator(.twice.)'//nl// &
        'implicit none'//nl// &
        'print *, 2 .in. [1,2], .twice. [1d0,2d0]'//nl// &
        'end program'//nl
    type(program_t)::p
    type(diagnostic_t)::d
    type(compiler_frontend_result_t)::front
    type(compiler_frontend_options_t)::options
    type(resolved_type_query_t)::q
    integer::which,e,j,n,f,a
    options%input_mode=INPUT_MODE_STANDARD;options%operating_mode=OPERATING_MODE_STRICT
    options%standardize=.false.;options%run_semantics=.true.
    call compile_frontend_from_string(source,front,options)
    if(.not.front%success()) error stop 'operator producer compilation failed'
    n=0
    do j=1,front%arena%entry_count
        if(.not.front%arena%has_node_at(j)) cycle
        select type(node=>front%arena%entries(j)%node)
        type is(binary_op_node)
            if(.not.allocated(node%operator)) cycle
            if(node%operator/='.in.'.and.node%operator/='.twice.') cycle
            q=query_resolved_type(front%arena,j);n=n+1
            if(.not.q%found) error stop 'operator result metadata missing'
            if(node%operator=='.in.') then
                if(q%type_kind/=TLOGICAL.or.q%kind_value/=4.or.q%rank/=0) &
                    error stop 'operator membership result metadata differs'
            else
                if(q%type_kind/=TREAL.or.q%kind_value/=8.or.q%rank/=1) &
                    error stop 'operator elemental result metadata differs'
            end if
        end select
    end do
    if(n/=2) error stop 'operator producer occurrences missing'
    do which=1,15
        call parse_subset(source,p,d)
        if(d%code/=0) error stop 'operator fixture rejected'
        e=0
        do j=1,p%ne
            if(p%expressions(j)%op=='.in.') e=j
        end do
        if(e==0) error stop 'operator fixture IR absent'
        f=p%expressions(e)%symbol;a=p%procedures(f)%args(2)
        select case(which)
        case(2);p%expressions(e)%symbol=2
        case(3);p%expressions(e)%op='.other.'
        case(4);p%expressions(e)%rank=1
        case(5);p%expressions(e)%typ=ty_integer
        case(6);p%operators(1)%is_public=.false.
        case(7);p%operators(1)%procedures(1)=2
        case(8);p%operators(1)%procedure_names(1)='twice'
        case(9);p%operators(1)%op='.other.'
        case(10);p%symbols(a)%rank=0
        case(11);p%symbols(a)%dummy_intent=2
        case(12);p%only_names(1,1)='operator(.twice.)'
        case(13);p%expressions(e)%args=p%expressions(e)%args(1:1)
        case(14);p%expressions(e)%args=p%expressions(e)%args(2:1:-1)
        case(15)
            do j=1,p%ne
                if(p%expressions(j)%op=='.twice.') p%expressions(j)%real_kind=4
            end do
        end select
        call verify_frontend(source,p,d)
        if((d%code==0).neqv.(which==1)) then
            print *,which
            if(allocated(d%message)) print *,d%message
            error stop 'operator adapter mutation regression'
        end if
    end do
    print '(a)','PASS: defined operators producer queries and 15 adapter checks'
end program
