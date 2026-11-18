! SPDX-License-Identifier: MIT
program test_typed_empty_arrays
    use,intrinsic::iso_fortran_env,only:int64
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    use fortfront_compiler
    use fortfront_ast,only:array_literal_node
    implicit none
    character(*),parameter::nl=new_line('a')
    character(:),allocatable::source,body
    type(program_t)::p,q
    type(diagnostic_t)::d
    type(compiler_frontend_options_t)::opts
    type(compiler_frontend_result_t)::front
    type(resolved_type_query_t)::typ
    integer::i,j,k,g,checks,context,seen
    checks=0
    do context=1,4
        select case(context)
        case(1);body='a=[integer(k)::]'
        case(2);body='if(kind([integer(k)::])/=8) error stop 1'
        case(3);body='a=[integer(k)::]+1_8'
        case(4);body='if(size([integer(k)::])/=0) error stop 1'
        end select
        source='program p'//nl//'implicit none'//nl//'integer,parameter::k=8,j=8'//nl// &
            'integer(8)::a(0)'//nl//body//nl//'end program'
        call parse_subset(source,p,d);call okay('parse')
        call verify_frontend(source,p,d);call okay('adapter')
        call execute_program(p,d);call okay('runtime');checks=checks+3
        g=0
        do i=1,p%ne
            if(p%expressions(i)%kind==ex_constructor)g=i
        end do
        if(g==0)error stop 'constructor absent'
        do j=1,33
            q=p
            associate(e=>q%expressions(g))
            select case(j)
            case(1);e%rank=0
            case(2);e%extent=1
            case(3);e%extent=-1
            case(4);e%dims(1)=1
            case(5);e%typ=ty_real
            case(6);e%real_kind=4
            case(7);e%real_kind=16
            case(8);e%character_len=0
            case(9);e%length_expr=1
            case(10);e%op=''
            case(11);e%op='forged'
            case(12);e%op='logical'
            case(13);e%constructor_kind_expr=0
            case(14);e%constructor_kind_expr=g
            case(15);e%constructor_kind_expr=q%ne+1
            case(16);e%left=1
            case(17);e%right=1
            case(18);e%symbol=1
            case(19);e%stride=1
            case(20);e%left2=1
            case(21);e%right2=1
            case(22);e%stride2=1
            case(23);e%generic_id=1
            case(24);e%bound_type=1
            case(25);e%bound_binding=1
            case(26);e%intrinsic_mask=1
            case(27);e%triplet(1)=.false.
            case(28);e%triplet(2)=.true.
            case(29);e%args=[e%constructor_kind_expr]
            case(30);deallocate(e%args)
            case(31);e%op='character'
            case(32);q%expressions(e%constructor_kind_expr)%scope=1
            case(33);e%third=1
            end select
            end associate
            d=diagnostic_t();call verify_frontend(source,q,d)
            if(d%code==0)then
                print *,context,j
                error stop 'adapter accepted forged empty constructor'
            end if
            d=diagnostic_t();call execute_program(q,d)
            if(d%code==0)then
                print *,context,j
                error stop 'runtime accepted forged empty constructor'
            end if
            checks=checks+2
        end do
        ! Equal-valued named parameters cannot be exchanged in source binding.
        q=p;k=q%expressions(g)%constructor_kind_expr
        do i=1,q%ns
            if(q%symbols(i)%name=='j')q%expressions(k)%symbol=i
        end do
        d=diagnostic_t();call verify_frontend(source,q,d)
        if(d%code==0)error stop 'adapter accepted different source parameter'
        checks=checks+1
        q=p;q%expressions(g)%scope=1
        d=diagnostic_t();call verify_frontend(source,q,d)
        if(d%code==0)error stop 'adapter accepted wrong constructor scope'
        d=diagnostic_t();call execute_program(q,d)
        if(d%code==0)error stop 'runtime accepted wrong constructor scope'
        checks=checks+2
    end do
    opts%input_mode=INPUT_MODE_STANDARD;opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.;opts%run_semantics=.true.
    source='program p'//nl//'implicit none'//nl//'integer,parameter::k=8'//nl// &
        'integer(8)::a(0)'//nl//'real(8)::b(0)'//nl//'logical::c(0)'//nl// &
        'a=[integer(k)::]'//nl//'b=(/real(kind=k)::/)'//nl//'c=[logical::]'//nl//'end program'
    call compile_frontend_from_string(source,front,opts)
    if(.not.front%success())error stop 'producer rejected typed empties'
    seen=0
    do i=1,front%arena%entry_count
        if(.not.front%arena%has_node_at(i))cycle
        select type(n=>front%arena%entries(i)%node)
        type is(array_literal_node)
            typ=query_resolved_type(front%arena,i)
            if(.not.allocated(n%element_indices))error stop 'producer elements absent'
            if(size(n%element_indices)/=0.or..not.typ%found.or.typ%rank/=1)error stop 'producer empty shape'
            select case(typ%type_kind)
            case(TINT,TREAL)
                if(typ%kind_value/=8)error stop 'producer numeric kind lost'
            case(TLOGICAL)
                if(typ%kind_value/=4)error stop 'producer logical kind lost'
            case default
                error stop 'producer type lost'
            end select
            seen=seen+1
        end select
    end do
    if(seen/=3)error stop 'producer constructors absent'
    checks=checks+3
    print *, 'PASS: typed empty constructor checks:',checks
contains
    subroutine okay(label)
        character(*),intent(in)::label
        if(d%code/=0)then
            print *,label,': ',d%message
            error stop 'unexpected baseline failure'
        end if
    end subroutine
end program
