! SPDX-License-Identifier: MIT
program test_row_gather
    use,intrinsic::iso_fortran_env,only:int64
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    use fortfront_compiler
    use fortfront_ast,only:assignment_node
    use ast_nodes_bounds,only:array_slice_node
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        'integer::a(3,2),b(2,2),idx(2)'//nl// &
        'a=reshape([1,2,3,4,5,6],[3,2])'//nl//'idx=[3,1]'//nl// &
        'b=a(idx,:)'//nl//'if(any(b/=reshape([3,1,6,4],[2,2]))) error stop 1'//nl//'end program'
    character(*),parameter::continued='program p'//nl//'implicit none'//nl// &
        'integer::x'//nl//'x=0'//nl//'if(.true.) &'//nl//' x=3'//nl// &
        'if(.false.) &'//nl//' x=4'//nl//'if(x/=3) error stop 1'//nl//'end program'
    character(*),parameter::actual_source='program p'//nl//'implicit none'//nl// &
        'integer::a(3,2)'//nl//'a=1'//nl//'call f((a([3,1],:)))'//nl//'contains'//nl// &
        'subroutine f(x)'//nl//'integer,intent(in)::x(:,:)'//nl// &
        'if(sum(x)/=4) error stop 1'//nl//'end subroutine'//nl//'end program'
    type(program_t)::p,q
    type(diagnostic_t)::d
    type(compiler_frontend_options_t)::opts
    type(compiler_frontend_result_t)::front
    type(resolved_type_query_t)::typ
    integer::i,j,g,checks,seen,pc
    checks=0
    call parse_subset(source,p,d);call okay('parse')
    call verify_frontend(source,p,d);call okay('adapter')
    call execute_program(p,d);call okay('runtime');checks=checks+3
    g=0
    do i=1,p%ne
        if(p%expressions(i)%kind==ex_gather_rows) g=i
    end do
    if(g==0) error stop 'gather IR absent'
    do j=1,26
        q=p
        associate(e=>q%expressions(g))
        select case(j)
        case(1);e%symbol=0
        case(2);e%rank=1
        case(3);e%extent=0
        case(4);e%dims=[2_int64,2_int64,1_int64]
        case(5);e%typ=ty_logical
        case(6);e%real_kind=16
        case(7);e%left=0
        case(8);e%right=1
        case(9);e%stride=1
        case(10);e%left2=1
        case(11);e%right2=1
        case(12);e%stride2=1
        case(13);e%left3=1
        case(14);e%third=1
        case(15);e%triplet(1)=.true.
        case(16);e%triplet(2)=.false.
        case(17);allocate(e%args(0))
        case(18);e%op='forged'
        case(19);e%length_expr=1
        case(20);e%generic_id=1
        case(21);e%bound_type=1
        case(22);e%bound_binding=1
        case(23);e%intrinsic_mask=1
        case(24);e%character_len=1
        case(25);e%left=g
        case(26);q%symbols(e%symbol)%is_pointer=.true.
        end select
        end associate
        d=diagnostic_t();call verify_frontend(source,q,d)
        if(d%code==0) then
            print *,j
            error stop 'adapter admitted forged gather'
        end if
        d=diagnostic_t();call execute_program(q,d)
        if(d%code==0) then
            print *,j
            error stop 'runtime admitted forged gather'
        end if
        checks=checks+2
    end do
    q=p;pc=0
    do i=1,q%nc
        if(q%code(i)%op==op_assign.and.q%code(i)%a==g) pc=i
    end do
    if(pc==0) error stop 'gather assignment missing'
    q%code(pc)%symbol=q%expressions(g)%symbol;q%code(pc)%c=g
    d=diagnostic_t();call execute_program(q,d)
    if(d%code==0) error stop 'runtime accepted scatter target'
    checks=checks+1
    call parse_subset(continued,q,d);call okay('continued parse')
    call verify_frontend(continued,q,d);call okay('continued adapter')
    call execute_program(q,d);call okay('continued runtime');checks=checks+3
    opts%input_mode=INPUT_MODE_STANDARD;opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.;opts%run_semantics=.true.
    call compile_frontend_from_string(source,front,opts)
    if(.not.front%success()) error stop 'producer rejected gather'
    seen=0
    do i=1,front%arena%entry_count
        if(.not.front%arena%has_node_at(i)) cycle
        select type(n=>front%arena%entries(i)%node)
        type is(array_slice_node)
            typ=query_resolved_type(front%arena,i)
            if(.not.typ%found.or.typ%rank/=2.or.typ%type_kind/=TINT.or.typ%kind_value/=4) &
                error stop 'producer lost vector result rank/type'
            seen=seen+1
        end select
    end do
    if(seen/=1) error stop 'producer gather missing'
    checks=checks+1
    call compile_frontend_from_string(continued,front,opts)
    if(.not.front%success()) error stop 'producer rejected continued action'
    seen=0
    do i=1,front%arena%entry_count
        if(.not.front%arena%has_node_at(i)) cycle
        select type(n=>front%arena%entries(i)%node)
        type is(assignment_node)
            if(n%is_keyword_argument) cycle
            if(n%line/=4.and.n%line/=6.and.n%line/=8) error stop 'action physical line lost'
            seen=seen+1
        end select
    end do
    if(seen/=3) error stop 'producer continued action missing'
    checks=checks+1
    call parse_subset(actual_source,q,d);call okay('actual parse')
    call verify_frontend(actual_source,q,d);call okay('actual adapter')
    call execute_program(q,d);call okay('actual runtime');checks=checks+3
    do i=1,q%ne
        if(q%expressions(i)%kind==ex_gather_rows) q%expressions(i)%parenthesized=.false.
    end do
    d=diagnostic_t();call verify_frontend(actual_source,q,d)
    if(d%code==0) error stop 'adapter accepted unparenthesized gather actual'
    d=diagnostic_t();call execute_program(q,d)
    if(d%code==0) error stop 'runtime accepted unparenthesized gather actual'
    checks=checks+2
    print *, 'PASS: row gather and producer safety checks:',checks
contains
    subroutine okay(label)
        character(*),intent(in)::label
        if(d%code/=0) then
            print *,label,': ',d%message
            error stop 'row gather native check failed'
        end if
    end subroutine
end program
