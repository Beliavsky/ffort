! SPDX-License-Identifier: MIT
program test_character_plus
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: execute_program
    use fortfront_compiler, only: compiler_frontend_result_t,compiler_frontend_options_t, &
        compile_frontend_from_string,INPUT_MODE_STANDARD,OPERATING_MODE_STRICT, &
        query_resolved_type,resolved_type_query_t,TINT,TREAL,TCHAR
    use fortfront_ast, only: binary_op_node,call_or_subscript_node
    use semantic_binary_ops_core, only: infer_binary_operation
    use type_system_unified, only: mono_type_t,create_mono_type
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source= &
        'module ops'//nl//'implicit none'//nl//'private'//nl// &
        'public::operator(+),choose'//nl// &
        'interface operator(+)'//nl//'module procedure addc,addi'//nl//'end interface'//nl// &
        'interface choose'//nl//'module procedure optional_f'//nl//'end interface'//nl//'contains'//nl// &
        'elemental function addc(a,b) result(r)'//nl// &
        'character(*),intent(in)::a,b'//nl//'character(len(a)+len(b))::r'//nl// &
        'r=a//b'//nl//'end function'//nl// &
        'elemental real(8) function addi(a,b) result(r)'//nl// &
        'character(*),intent(in)::a'//nl//'integer,intent(in)::b'//nl// &
        'r=real(len(a)+b,8)'//nl//'end function'//nl// &
        'integer function optional_f(a,b,c) result(r)'//nl// &
        'integer,optional,intent(in)::a,b'//nl//'integer,intent(in)::c'//nl// &
        'r=c'//nl//'if(present(a))r=r+a'//nl//'if(present(b))r=r+b'//nl//'end function'//nl// &
        'end module'//nl//'program p'//nl//'use ops,only:operator(+),choose'//nl// &
        'implicit none'//nl//'character(2)::s'//nl//'real(8)::a(3)'//nl//'integer::k'//nl// &
        's="a"+"b"'//nl//'a="x"+[1,2,3]'//nl//'k=choose(c=3)'//nl//'k=k+2'//nl// &
        'if(s/="ab")error stop 1'//nl//'if(any(a/=[2d0,3d0,4d0]))error stop 2'//nl// &
        'if(k/=5)error stop 3'//nl//'end program'//nl
    type(program_t)::p
    type(diagnostic_t)::d
    type(compiler_frontend_result_t)::front
    type(compiler_frontend_options_t)::options
    type(resolved_type_query_t)::q
    type(mono_type_t)::char_type,inferred
    type(binary_op_node)::node_copy
    integer::which,e,j,n,c,f,a,checks,cc_node,optional_calls
    options%input_mode=INPUT_MODE_STANDARD;options%operating_mode=OPERATING_MODE_STRICT
    options%standardize=.false.;options%run_semantics=.true.
    call compile_frontend_from_string(source,front,options)
    if(.not.front%success()) error stop 'character-plus producer compilation failed'
    n=0;cc_node=0;optional_calls=0;checks=0
    do j=1,front%arena%entry_count
        if(.not.front%arena%has_node_at(j)) cycle
        select type(node=>front%arena%entries(j)%node)
        type is(call_or_subscript_node)
            if(.not.allocated(node%name))cycle
            if(node%name/='choose')cycle
            q=query_resolved_type(front%arena,j)
            if(.not.q%found.or.q%type_kind/=TINT.or.q%kind_value/=4.or.q%rank/=0) &
                error stop 'omitted OPTIONAL generic result metadata missing'
            optional_calls=optional_calls+1
        end select
    end do
    ! Identify the two CHARACTER actual occurrences by resolved type, without
    ! relying on hard-coded source line numbers in future maintenance.
    n=0;cc_node=0
    do j=1,front%arena%entry_count
        if(.not.front%arena%has_node_at(j))cycle
        select type(node=>front%arena%entries(j)%node)
        type is(binary_op_node)
            if(.not.allocated(node%operator))cycle
            if(node%operator/='+'.or.node%left_index<=0)cycle
            q=query_resolved_type(front%arena,node%left_index)
            if(.not.q%found.or.q%type_kind/=TCHAR)cycle
            q=query_resolved_type(front%arena,j)
            if(.not.q%found)error stop 'CHARACTER plus lost producer metadata'
            if(q%type_kind==TCHAR)then
                if(q%rank/=0.or.q%kind_value/=1)error stop 'CHARACTER result metadata differs'
                cc_node=j
            else
                if(q%type_kind/=TREAL.or.q%rank/=1.or.q%kind_value/=8)error stop 'REAL result metadata differs'
            end if
            n=n+1
        end select
    end do
    if(n/=2.or.optional_calls/=1.or.cc_node==0)error stop 'producer occurrences missing'
    checks=checks+3
    ! The helper's default remains the lazy convenience rewrite; explicit
    ! standard mode never rewrites the source intrinsic symbol to concatenation.
    select type(node=>front%arena%entries(cc_node)%node)
    type is(binary_op_node)
        node_copy=node
    end select
    char_type=create_mono_type(TCHAR)
    inferred=infer_binary_operation(front%arena,cc_node,node_copy,char_type,char_type,preserve_plus=.true.)
    select type(node=>front%arena%entries(cc_node)%node)
    type is(binary_op_node)
        if(node%operator/='+')error stop 'standard helper changed source operator'
    end select
    inferred=infer_binary_operation(front%arena,cc_node,node_copy,char_type,char_type)
    select type(node=>front%arena%entries(cc_node)%node)
    type is(binary_op_node)
        if(node%operator/='//')error stop 'lazy helper lost default concatenation rewrite'
    end select
    checks=checks+2
    do which=1,27
        call parse_subset(source,p,d)
        if(d%code/=0)then
            print *,d%message
            error stop 'character-plus baseline parse failed'
        end if
        e=0;c=0
        do j=1,p%ne
            if(p%expressions(j)%op/='+'.or.p%expressions(j)%kind/=ex_user_call)cycle
            if(p%expressions(j)%typ==ty_real)e=j
            if(p%expressions(j)%typ==ty_character)c=j
        end do
        if(e==0.or.c==0)error stop 'plus IR missing'
        f=p%expressions(e)%symbol;a=p%procedures(f)%args(2)
        select case(which)
        case(2);p%expressions(e)%symbol=p%expressions(c)%symbol
        case(3);p%expressions(e)%op='-'
        case(4);p%expressions(e)%rank=0
        case(5);p%expressions(e)%typ=ty_integer
        case(6);p%expressions(e)%real_kind=4
        case(7);p%operators(1)%is_public=.false.
        case(8);p%operators(1)%procedures(2)=p%operators(1)%procedures(1)
        case(9);p%operators(1)%procedure_names(2)='addc'
        case(10);p%operators(1)%op='-'
        case(11);p%symbols(a)%rank=1
        case(12);p%symbols(a)%dummy_intent=2
        case(13);p%symbols(a)%is_optional=.true.
        case(14);p%only_names(1,1)='choose'
        case(15);p%expressions(e)%args=p%expressions(e)%args(1:1)
        case(16);p%expressions(e)%args=p%expressions(e)%args(2:1:-1)
        case(17);p%expressions(c)%character_len=1
        case(18);p%expressions(e)%kind=ex_binary
        case(19);p%procedures(f)%is_elemental=.false.
        case(20);p%procedures(f)%is_subroutine=.true.
        case(21);p%symbols(p%procedures(f)%result_symbol)%real_kind=4
        case(22);p%operators(1)%module_id=0
        case(23);p%expressions(c)%op='//'
        case(24);p%symbols(p%procedures(f)%args(1))%typ=ty_integer
        case(25);p%expressions(e)%args(1)=0
        case(26);deallocate(p%expressions(e)%args)
        case(27);p%expressions(e)%args(2)=p%ne+1
        end select
        call verify_frontend(source,p,d)
        if((d%code==0).neqv.(which==1))then
            print *,which
            if(allocated(d%message))print *,d%message
            error stop 'character-plus adapter mutation regression'
        end if
        checks=checks+1
    end do
    do which=1,7
        call parse_subset(source,p,d)
        if(d%code/=0)error stop 'runtime fixture parse failed'
        e=0
        do j=1,p%ne
            if(p%expressions(j)%kind==ex_user_call.and.p%expressions(j)%op=='+'.and. &
                p%expressions(j)%typ==ty_real)e=j
        end do
        f=p%expressions(e)%symbol
        select case(which)
        case(2);p%procedures(f)%is_elemental=.false.
        case(3);p%procedures(f)%is_pure=.false.
        case(4);p%symbols(p%procedures(f)%args(1))%dummy_intent=3
        case(5);p%symbols(p%procedures(f)%result_symbol)%rank=1
        case(6);p%expressions(e)%symbol=0
        case(7);p%expressions(e)%args=p%expressions(e)%args(1:1)
        end select
        call execute_program(p,d)
        if((d%code==0).neqv.(which==1))then
            print *,which
            if(allocated(d%message))print *,d%message
            error stop 'CHARACTER plus ordinary user-call runtime guard failed'
        end if
        checks=checks+1
    end do
    print '(a,i0,a)','PASS: ',checks,' CHARACTER plus producer/helper/adapter/runtime checks'
end program
