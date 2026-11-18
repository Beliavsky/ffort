! SPDX-License-Identifier: MIT
! Producer roots and independent adapter operand/binding/cache validation.
program test_logical_initializer_frontend
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fortfront_compiler,only:compiler_frontend_result_t,compiler_frontend_options_t, &
        compile_frontend_from_string,INPUT_MODE_STANDARD,OPERATING_MODE_STRICT
    use ast_nodes_core,only:binary_op_node
    use fortfront_ast,only:declaration_node
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    type(compiler_frontend_result_t)::front
    type(compiler_frontend_options_t)::opts
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        'logical,parameter::a(2)=[.true.,.false.]'//nl// &
        'logical,parameter::b(2)=.not.a.or.a'//nl// &
        'logical,parameter::c=.true..and..false.,d=.false..eqv..false.'//nl// &
        'print *,b,c,d'//nl//'end program'
    integer::j,k,b,e,which,found
    character(:),allocatable::changed,op
    opts%input_mode=INPUT_MODE_STANDARD;opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.;opts%run_semantics=.true.
    call compile_frontend_from_string(source,front,opts)
    if(.not.front%success()) error stop 'producer rejected logical initialization'
    found=0
    do j=1,front%arena%entry_count
        if(.not.front%arena%has_node_at(j))cycle
        select type(node=>front%arena%entries(j)%node)
        type is(declaration_node)
            if(.not.allocated(node%var_name))cycle
            op=''
            select case(node%var_name)
            case('b');op='.or.'
            case('c');op='.and.'
            case('d');op='.eqv.'
            end select
            if(len(op)==0)cycle
            k=node%initializer_index
            if(.not.front%arena%has_node_at(k)) error stop 'initializer missing'
            select type(expr=>front%arena%entries(k)%node)
            type is(binary_op_node)
                if(expr%operator/=op) error stop 'producer truncated logical initializer'
            class default
                error stop 'producer initializer root is not binary'
            end select
            found=found+1
        end select
    end do
    if(found/=3) error stop 'producer declaration count'
    do which=1,6
        call parse_subset(source,p,d)
        if(d%code/=0) error stop 'guard rejected baseline'
        b=0
        do j=1,p%ns
            if(p%symbols(j)%name=='b')b=j
        end do
        if(b==0) error stop 'missing b'
        e=p%symbols(b)%initializer_expr;changed=source
        select case(which)
        case(2);p%expressions(e)%op='.and.'
        case(3);p%expressions(e)%left=p%expressions(e)%right
        case(4);p%expressions(p%expressions(e)%right)%symbol=b
        case(5);p%symbols(b)%constant_values(1)%l=.false.
        case(6);p%expressions(e)%rank=0;p%expressions(e)%extent=0
        end select
        call verify_frontend(changed,p,d)
        if(which==1) then
            if(d%code/=0) then
                print *,d%message
                error stop 'adapter rejected baseline'
            end if
        else if(d%code==0) then
            print *,which
            error stop 'adapter admitted modified logical initializer'
        end if
    end do
    print '(a)','PASS: three logical producer roots, baseline and five adapter mutations'
end program
