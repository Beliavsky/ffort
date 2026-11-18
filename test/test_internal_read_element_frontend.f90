! SPDX-License-Identifier: MIT
! Draft only: integrated build/execution and independent review still required.
program test_internal_read_element_frontend
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend,read_element_unit_text_matches
    use fortfront_compiler, only: compiler_frontend_options_t,compiler_frontend_result_t, &
        compile_frontend_from_string,INPUT_MODE_STANDARD,OPERATING_MODE_STRICT
    use ast_nodes_io, only: read_statement_node
    use fortfront_ast, only: call_or_subscript_node,binary_op_node
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::decl='program p'//nl//'implicit none'//nl// &
        'character(8)::a(2),b(2)'//nl//'integer::i,j,n,ios,other'//nl
    character(*),parameter::init='i=1'//nl//'j=2'//nl//'a(1)="7"'//nl
    character(*),parameter::stmt='read(a(i+0),*,iostat=ios)n'//nl
    character(:),allocatable::source,changed
    type(program_t)::p,q
    type(diagnostic_t)::d
    type(compiler_frontend_options_t)::opts
    type(compiler_frontend_result_t)::front
    type(read_statement_node)::forged
    integer::checks,k,pc,file,index_root,leaf,other_array,other_index,which,found,ast
    checks=0;source=decl//init//stmt//'end program'//nl
    d=diagnostic_t();call parse_subset(source,p,d);call expect(d%code==0,'baseline parse')
    d=diagnostic_t();call verify_frontend(source,p,d);call expect(d%code==0,'baseline structural agreement')
    pc=0;other_array=0;other_index=0
    do k=1,p%nc
        if(p%code(k)%op==op_read_internal)pc=k
    end do
    do k=1,p%ns
        if(p%symbols(k)%name=='b')other_array=k
        if(p%symbols(k)%name=='j')other_index=k
    end do
    call expect(pc>0.and.other_array>0.and.other_index>0,'fixture identities')
    file=p%code(pc)%a;index_root=p%expressions(file)%left;leaf=p%expressions(index_root)%left
    call expect(p%expressions(file)%kind==ex_element,'element file')
    call expect(p%expressions(index_root)%kind==ex_binary,'arithmetic index retained')
    call expect(p%expressions(leaf)%kind==ex_variable,'index variable retained')
    opts%input_mode=INPUT_MODE_STANDARD;opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.;opts%run_semantics=.true.
    call compile_frontend_from_string(source,front,opts)
    call expect(front%success(),'producer accepts bounded internal element')
    found=0
    do k=1,front%arena%entry_count
        if(.not.front%arena%has_node_at(k))cycle
        select type(node=>front%arena%entries(k)%node)
        type is(read_statement_node)
            found=found+1
            call expect(allocated(node%unit_spec).and.allocated(node%specifiers),'producer controls present')
            call expect(node%unit_spec=='a(i+0)'.and.node%specifiers(1)%value=='a(i+0)', &
                'both producer passes retain full UNIT spelling')
            call expect(read_element_unit_text_matches(front%tokens,node),'original text bound to source tokens')
            forged=node
            forged%unit_spec='a(i+1)'
            call expect(.not.read_element_unit_text_matches(front%tokens,forged),'UNIT-only corruption')
            forged=node
            forged%specifiers(1)%value='a(i+1)'
            call expect(.not.read_element_unit_text_matches(front%tokens,forged),'control-only corruption')
            forged%unit_spec='a(i+1)'
            call expect(forged%specifiers(1)%value_node_index==node%specifiers(1)%value_node_index, &
                'dual-text corruption leaves structural AST unchanged')
            call expect(.not.read_element_unit_text_matches(front%tokens,forged),'dual-text corruption rejected')
            forged=node
            forged%unit_spec='a';forged%specifiers(1)%value='a'
            call expect(.not.read_element_unit_text_matches(front%tokens,forged),'base-name-only text rejected')
            forged=node;forged%line=forged%line+1
            call expect(.not.read_element_unit_text_matches(front%tokens,forged),'forged READ location rejected')
            ast=node%specifiers(1)%value_node_index
            call expect(front%arena%has_node_at(ast),'producer UNIT AST exists')
            select type(unit=>front%arena%entries(ast)%node)
            type is(call_or_subscript_node)
                call expect(unit%name=='a','producer base')
                call expect(allocated(unit%arg_indices),'producer index storage')
                call expect(size(unit%arg_indices)==1,'producer exact rank')
                ast=unit%arg_indices(1)
                select type(ix=>front%arena%entries(ast)%node)
                type is(binary_op_node)
                    call expect(.true.,'producer arithmetic subtree retained')
                class default
                    call expect(.false.,'producer arithmetic subtree missing')
                end select
            class default
                call expect(.false.,'producer UNIT is not structural element')
            end select
        end select
    end do
    call expect(found==1,'one producer READ')
    ! Same base alone is not agreement: differing index, format and status fail.
    call source_reject('read(a(j+0),*,iostat=ios)n','same base different index')
    call source_reject('read(a(i+1),*,iostat=ios)n','same base different literal')
    call source_reject('read(b(i+0),*,iostat=ios)n','different file base')
    call source_reject('read(a(i+0),*,iostat=other)n','different IOSTAT control')
    call source_reject('read(a(i+0),"(i2)",iostat=ios)n','different format control')
    changed=decl//init//'read(unit=a(i+0),fmt=*,iostat=ios)n'//nl//'end program'//nl
    d=diagnostic_t();call verify_frontend(changed,p,d)
    call expect(d%code==0,'keyword controls preserve exact structural binding')
    do which=1,9
        q=p
        select case(which)
        case(1);q%expressions(leaf)%symbol=other_index
        case(2);q%expressions(file)%symbol=other_array
        case(3);q%expressions(index_root)%left=index_root
        case(4);q%expressions(index_root)%right=index_root
        case(5);q%expressions(file)%left=file
        case(6);q%expressions(index_root)%op='-'
        case(7);q%expressions(file)%right=leaf
        case(8);q%code(pc)%b=file
        case(9);q%expressions(file)%left=q%ne+1
        end select
        d=diagnostic_t();call verify_frontend(source,q,d)
        call expect(d%code/=0,'forged complete UNIT/control/index or cycle rejected')
    end do
    print *, 'internal READ element producer/adapter draft checks:',checks
contains
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        if(.not.ok)then
            print *,label
            error stop 1
        end if
        checks=checks+1
    end subroutine
    subroutine source_reject(read_statement,label)
        character(*),intent(in)::read_statement,label
        changed=decl//init//read_statement//nl//'end program'//nl
        d=diagnostic_t();call verify_frontend(changed,p,d)
        call expect(d%code/=0,label)
    end subroutine
end program
