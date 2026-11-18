! SPDX-License-Identifier: MIT
! Independent public-IR/runtime checks: parse baseline once, then mutate IR only.
! No source adapter is consulted after mutation. This file is intentionally kept
! outside integration.tar.gz until the owner authorizes a build and integration.
program test_constructor_implied_do_guards
    use, intrinsic :: iso_fortran_env, only: error_unit, int64, real64
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_runtime, only: execute_program, evaluate_constant, evaluate_constant_array
    implicit none
    character(*), parameter :: nl=new_line('a')
    character(*), parameter :: source='program p'//nl//'implicit none'//nl// &
        'integer::i,j,a(3)'//nl//'i=88'//nl//'a=[(i,i=1,3)]'//nl// &
        'if(any(a/=[1,2,3])) error stop 11'//nl//'if(i/=88) error stop 12'//nl//'end program'
    type(program_t) :: p,q,constant_body
    type(diagnostic_t) :: d
    type(value_t) :: scalar
    type(expr_t) :: extra
    type(value_t), allocatable :: values(:)
    integer :: root,idx,wrapper,assign_pc,s,other,j,which,checks,new,inside,inquiry,offset
    integer :: owner_ids(9),index_ids(9),symbol_ids(9)
    integer :: nested_owner,nested_index,nested_wrapper,query,reduce
    character(100) :: label

    checks=0;which=0;root=0;idx=0;wrapper=0;assign_pc=0;other=0
    call parse_subset(source,p,d)
    call expect(d%code==0,'baseline parses')
    do j=1,p%ne
        if(p%expressions(j)%kind==ex_constructor_do) root=j
        if(p%expressions(j)%kind==ex_constructor_index) idx=j
    end do
    call expect(root>0.and.idx>0,'new IR expression kinds present')
    s=p%expressions(root)%symbol
    do j=1,p%ns
        if(p%symbols(j)%name=='j') other=j
    end do
    do j=1,p%nc
        if(p%code(j)%op/=op_assign) cycle
        if(p%code(j)%symbol<1.or.p%code(j)%symbol>p%ns) cycle
        if(p%symbols(p%code(j)%symbol)%name=='a') then
            assign_pc=j;wrapper=p%code(j)%a
        end if
    end do
    call expect(s>0.and.other>0.and.assign_pc>0.and.wrapper>0,'baseline identities')
    call expect(p%expressions(wrapper)%kind==ex_constructor,'do has constructor value wrapper')
    call expect(p%expressions(idx)%constructor_owner==root,'index records lexical owner identity')
    call expect(valid_constructor_index(p,idx),'baseline index metadata valid')
    call expect(valid_constructor_do(p,root),'baseline complete lexical tree valid')
    call expect(valid_constructor_tree(p,wrapper),'baseline complete constructor tree valid')
    call expect(.not.valid_constructor_tree(p,idx),'index is not an independently rooted constructor tree')
    ! The root->index body edge and index->root OWNER link are not a graph cycle.
    call expect(p%expressions(root)%args(1)==idx,'owner link is not traversed as a body edge')
    d=diagnostic_t();call execute_program(p,d)
    call expect(d%code==0,'source-free runtime baseline preserves outer value')
    d=diagnostic_t();call execute_program(p,d)
    call expect(d%code==0,'independent runtime executions do not retain owner frames')

    ! Allowed source-location/parenthesis metadata is not source binding.
    q=p;q%expressions(idx)%line=123;q%expressions(idx)%column=47
    q%expressions(idx)%parenthesized=.true.
    q%expressions(root)%line=122;q%expressions(root)%column=46
    call expect(valid_constructor_index(q,idx),'index parentheses/location metadata allowed')
    call expect(valid_constructor_do(q,root),'location changes do not break structural validity')

    ! Inherited storage attributes are intentionally not index attributes.
    do which=1,7
        q=p
        select case(which)
        case(1);q%symbols(s)%is_saved=.true.
        case(2);q%symbols(s)%is_dummy=.true.;q%symbols(s)%dummy_intent=1
        case(3);q%symbols(s)%is_optional=.true.
        case(4);q%symbols(s)%is_allocatable=.true.
        case(5);q%symbols(s)%is_pointer=.true.
        case(6);q%symbols(s)%is_target=.true.
        case(7);q%symbols(s)%scope=-1
        end select
        call expect(valid_constructor_index(q,idx),'inherited storage attribute does not bind index storage')
        call expect(valid_constructor_do(q,root),'inherited storage attribute allows lexical tree')
    end do
    q=p;q%symbols(s)%real_kind=8
    q%expressions(idx)%real_kind=8;q%expressions(root)%real_kind=8
    call expect(valid_constructor_index(q,idx),'INTEGER8 index inherits symbol kind')
    call expect(valid_constructor_do(q,root),'INTEGER8 body and result kind agree')

    ! Each malformed index is rejected independently at both public boundaries.
    do which=1,44
        q=p
        select case(which)
        case(1);q%expressions(idx)%constructor_owner=0
        case(2);q%expressions(idx)%constructor_owner=-1
        case(3);q%expressions(idx)%constructor_owner=q%ne+1
        case(4);q%expressions(idx)%constructor_owner=idx
        case(5);q%expressions(idx)%symbol=0
        case(6);q%expressions(idx)%symbol=q%ns+1
        case(7);q%expressions(idx)%symbol=other
        case(8);q%expressions(idx)%typ=ty_real
        case(9);q%expressions(idx)%real_kind=8
        case(10);q%expressions(idx)%real_kind=16
        case(11);q%expressions(idx)%rank=1
        case(12);q%expressions(idx)%extent=1_int64
        case(13);q%expressions(idx)%dims(1)=1_int64
        case(14);q%expressions(idx)%character_len=0
        case(15);q%expressions(idx)%scope=-1
        case(16);q%expressions(idx)%scope=q%np+1
        case(17);q%expressions(idx)%length_expr=1
        case(18);q%expressions(idx)%constructor_kind_expr=1
        case(19);q%expressions(idx)%generic_id=1
        case(20);q%expressions(idx)%bound_type=1
        case(21);q%expressions(idx)%bound_binding=1
        case(22);q%expressions(idx)%intrinsic_mask=1
        case(23);q%expressions(idx)%left=1
        case(24);q%expressions(idx)%right=1
        case(25);q%expressions(idx)%stride=1
        case(26);q%expressions(idx)%left2=1
        case(27);q%expressions(idx)%right2=1
        case(28);q%expressions(idx)%stride2=1
        case(29);q%expressions(idx)%left3=1
        case(30);q%expressions(idx)%right3=1
        case(31);q%expressions(idx)%stride3=1
        case(32);q%expressions(idx)%third=1
        case(33);q%expressions(idx)%op='forged'
        case(34);q%expressions(idx)%args=[integer::]
        case(35);q%expressions(idx)%value%tag=ty_integer
        case(36);q%expressions(idx)%value%s=''
        case(37);allocate(q%expressions(idx)%value%record)
        case(38);q%expressions(idx)%triplet(1)=.false.
        case(39);q%expressions(idx)%triplet(2)=.true.
        case(40);q%expressions(idx)%value%i=1_int64
        case(41);q%expressions(idx)%value%r=1.0_real64
        case(42);q%expressions(idx)%value%l=.true.
        case(43);q%expressions(idx)%value%real_kind=8
        case(44);q%expressions(idx)%kind=ex_variable
        end select
        write(label,'(a,i0)') 'malformed index metadata #',which
        call expect(.not.valid_constructor_index(q,idx),trim(label))
        call reject_tree(q,root,trim(label))
    end do

    ! Reject bad inherited type metadata, without confusing storage attributes.
    do which=1,6
        q=p
        select case(which)
        case(1);q%symbols(s)%typ=ty_real
        case(2);q%symbols(s)%rank=1
        case(3);q%symbols(s)%is_parameter=.true.
        case(4);q%symbols(s)%is_intrinsic=.true.
        case(5);q%symbols(s)%real_kind=8
        case(6);q%symbols(s)%real_kind=16
        end select
        call expect(.not.valid_constructor_index(q,idx),'bad inherited declaration rejected by index gate')
        call reject_tree(q,root,'bad inherited declaration rejected by complete tree/runtime')
    end do

    ! Control and body shape/metadata mutations. Do not use source verification.
    do which=1,47
        q=p
        select case(which)
        case(1);q%expressions(root)%constructor_owner=root
        case(2);q%expressions(root)%rank=0
        case(3);q%expressions(root)%extent=0_int64
        case(4);q%expressions(root)%dims(1)=1_int64
        case(5);q%expressions(root)%typ=ty_real
        case(6);q%expressions(root)%real_kind=8
        case(7);q%expressions(root)%character_len=0
        case(8);q%expressions(root)%length_expr=1
        case(9);q%expressions(root)%constructor_kind_expr=1
        case(10);q%expressions(root)%generic_id=1
        case(11);q%expressions(root)%bound_type=1
        case(12);q%expressions(root)%bound_binding=1
        case(13);q%expressions(root)%intrinsic_mask=1
        case(14);q%expressions(root)%parenthesized=.true.
        case(15);q%expressions(root)%op='forged'
        case(16);q%expressions(root)%op='character'
        case(17);q%expressions(root)%left2=1
        case(18);q%expressions(root)%right2=1
        case(19);q%expressions(root)%stride2=1
        case(20);q%expressions(root)%left3=1
        case(21);q%expressions(root)%right3=1
        case(22);q%expressions(root)%stride3=1
        case(23);q%expressions(root)%third=1
        case(24);q%expressions(root)%triplet(1)=.false.
        case(25);q%expressions(root)%value%tag=ty_integer
        case(26);q%expressions(root)%value%s=''
        case(27);allocate(q%expressions(root)%value%record)
        case(28);q%expressions(root)%symbol=0
        case(29);q%expressions(root)%symbol=q%ns+1
        case(30);q%expressions(root)%symbol=other
        case(31);deallocate(q%expressions(root)%args)
        case(32);q%expressions(root)%args=[integer::]
        case(33);q%expressions(root)%args=[(idx,j=1,65)]
        case(34);q%expressions(root)%args(1)=0
        case(35);q%expressions(root)%args(1)=q%ne+1
        case(36);q%expressions(root)%args(1)=root
        case(37);q%expressions(root)%left=0
        case(38);q%expressions(root)%right=q%ne+1
        case(39);q%expressions(root)%stride=-1
        case(40);q%expressions(root)%left=idx
        case(41);q%expressions(root)%right=idx
        case(42);q%expressions(root)%stride=idx
        case(43);q%expressions(root)%value%i=1_int64
        case(44);q%expressions(root)%value%r=1.0_real64
        case(45);q%expressions(root)%value%l=.true.
        case(46);q%expressions(root)%value%real_kind=8
        case(47);q%expressions(idx)%rank=2
        end select
        write(label,'(a,i0)') 'malformed do metadata/body/control #',which
        call reject_tree(q,root,trim(label))
    end do

    q=p;q%expressions(idx)%kind=ex_variable;q%expressions(idx)%constructor_owner=0
    call reject_tree(q,root,'ordinary variable body cannot substitute for active index node')

    ! Metadata-only index validity is not lexical membership. The other owner
    ! exists, has matching symbol/type/scope, but is not on this body's stack.
    q=p;call append_expr(q,p%expressions(root),new)
    q%expressions(idx)%constructor_owner=new
    call expect(valid_constructor_index(q,idx),'detached owner reference passes metadata-only index gate')
    call reject_tree(q,root,'wrong lexical owner rejected despite valid standalone index metadata')

    ! A same-typed alternate scalar is legal only if owner and all index nodes
    ! agree. This test deliberately does not assert agreement with source text.
    q=p;q%expressions(root)%symbol=other;q%expressions(idx)%symbol=other
    call expect(valid_constructor_index(q,idx),'coherently changed scalar identity has valid metadata')
    call expect(valid_constructor_do(q,root),'coherently changed identity is structurally valid')

    ! A forged ordinary variable in this index's control must not read the
    ! outer variable: its name belongs to the statement entity throughout DO.
    q=p
    call append_expr(q,expr_t(kind=ex_variable,typ=ty_integer,symbol=s,scope=0),new)
    q%expressions(root)%left=new
    call reject_tree(q,root,'own control cannot be rebound to ordinary outer variable')

    ! Own-index inquiry operands are metadata, not forbidden reads of its
    ! undefined value. All three generated start controls evaluate to one.
    do which=1,3
        q=p
        extra=expr_t(kind=ex_call,typ=ty_integer,scope=0,args=[idx])
        select case(which)
        case(1);extra%op='kind';offset=3
        case(2);extra%op='digits';offset=30
        case(3);extra%op='huge';offset=2147483646
        end select
        call append_expr(q,extra,inquiry)
        extra=expr_t(kind=ex_literal,typ=ty_integer,scope=0, &
            value=value_t(tag=ty_integer,i=int(offset,int64)))
        call append_expr(q,extra,inside)
        extra=expr_t(kind=ex_binary,typ=ty_integer,scope=0,op='-',left=inquiry,right=inside)
        call append_expr(q,extra,new)
        q%expressions(root)%left=new
        call expect(valid_constructor_do(q,root),'own-index inquiry is valid without an active value')
        d=diagnostic_t();call execute_program(q,d)
        call expect(d%code==0,'own-index control inquiry does not read outer or undefined index data')
        q%expressions(new)%op='+';q%expressions(new)%right=idx
        call reject_tree(q,root,'inquiry plus own index value remains forbidden')
    end do

    ! A constructor in an outer control inquiry needs the whole ancestor path.
    ! This makes SIZE([(j,j=1,KIND(i))])-1 equal three while outer i is pending.
    q=p;extra=p%expressions(root);extra%symbol=other
    call append_expr(q,extra,nested_owner)
    extra=p%expressions(idx);extra%symbol=other;extra%constructor_owner=nested_owner
    call append_expr(q,extra,nested_index)
    q%expressions(nested_owner)%args=[nested_index]
    extra=expr_t(kind=ex_call,typ=ty_integer,op='kind',scope=0,args=[idx])
    call append_expr(q,extra,inquiry)
    q%expressions(nested_owner)%right=inquiry
    extra=p%expressions(wrapper);extra%args=[nested_owner]
    call append_expr(q,extra,nested_wrapper)
    extra=expr_t(kind=ex_call,typ=ty_integer,op='size',scope=0,args=[nested_wrapper])
    call append_expr(q,extra,query)
    extra=expr_t(kind=ex_binary,typ=ty_integer,op='-',scope=0, &
        left=query,right=p%expressions(root)%left)
    call append_expr(q,extra,reduce)
    q%expressions(root)%right=reduce
    call expect(valid_constructor_tree(q,wrapper),'complete ancestor path validates nested control constructor')
    call expect(.not.valid_constructor_tree(q,nested_wrapper),'detached nested root cannot invent its outer lexical owner')
    d=diagnostic_t();call execute_program(q,d)
    call expect(d%code==0,'nested control constructor metadata inquiry executes with pending outer owner')
    d=diagnostic_t();call evaluate_constant_array(q,nested_wrapper,values,d)
    call expect(d%code/=0,'runtime rejects nested root evaluated without its containing lexical tree')
    q%expressions(inquiry)%op='abs'
    call reject_tree(q,root,'value call cannot replace type-only inquiry of pending outer index')
    q%expressions(inquiry)%op='kind'
    q%expressions(nested_owner)%symbol=s;q%expressions(nested_index)%symbol=s
    call reject_tree(q,root,'nested index cannot reuse pending outer index name in control expression')

    ! General expression cycles in a control or body are not OWNER edges.
    q=p
    call append_expr(q,expr_t(kind=ex_binary,typ=ty_integer,op='+',scope=0),new)
    q%expressions(new)%left=new;q%expressions(new)%right=p%expressions(root)%left
    q%expressions(root)%args=[new]
    call reject_tree(q,root,'indirect cyclic body rejected')
    q%expressions(root)%args=[idx];q%expressions(root)%left=new
    call reject_tree(q,root,'indirect cyclic control rejected')

    ! Detached index evaluation and direct DO value evaluation must fail even
    ! when each node would be structurally valid in its proper lexical context.
    d=diagnostic_t();call evaluate_constant(p,idx,scalar,d)
    call expect(d%code/=0,'detached index scalar evaluation has no active runtime owner')
    d=diagnostic_t();call evaluate_constant_array(p,root,values,d)
    call expect(d%code/=0,'DO control node is not a standalone array value')
    q=p;q%code(assign_pc)%a=root
    d=diagnostic_t();call execute_program(q,d)
    call expect(d%code==2,'direct DO assignment bypassing constructor wrapper rejected')
    q=p;q%code(assign_pc)%a=idx
    d=diagnostic_t();call execute_program(q,d)
    call expect(d%code==2,'detached index in instruction rejected')

    ! No index leaf is needed to expose root metadata. This prevents an invalid
    ! owner scope or kind from being rejected only accidentally by a child index.
    constant_body=p;extra=p%expressions(p%expressions(root)%left)
    call append_expr(constant_body,extra,new)
    constant_body%expressions(root)%args=[new]
    call expect(valid_constructor_do(constant_body,root),'constant body is a valid index-free tree')
    q=constant_body
    q%expressions(root)%scope=-1
    q%expressions(q%expressions(root)%left)%scope=-1
    q%expressions(q%expressions(root)%right)%scope=-1
    q%expressions(q%expressions(root)%args(1))%scope=-1
    call reject_tree(q,root,'owner scope range validated even without index references')
    q=constant_body
    q%expressions(root)%real_kind=16
    q%expressions(q%expressions(root)%args(1))%real_kind=16
    call reject_tree(q,root,'unsupported common INTEGER kind rejected without an index leaf')

    ! Build depth limits directly in IR, so parser limits cannot mask runtime
    ! guards. Every nested level gets a distinct inherited symbol and owner ID.
    call make_depth(8,q,owner_ids,index_ids,symbol_ids)
    call expect(valid_constructor_do(q,root),'exactly eight lexical levels accepted')
    inside=owner_ids(2)
    q%expressions(inside)%left=idx
    call expect(valid_constructor_do(q,root),'inner controls may reference active outer index')
    q%expressions(inside)%left=index_ids(2)
    call reject_tree(q,root,'inner controls cannot reference their own not-yet-active index')
    call make_depth(9,q,owner_ids,index_ids,symbol_ids)
    call reject_tree(q,root,'ninth lexical level rejected from public IR')
    call make_depth(2,q,owner_ids,index_ids,symbol_ids)
    q%expressions(owner_ids(2))%symbol=s
    q%expressions(index_ids(2))%symbol=s
    call reject_tree(q,root,'nested repeated inherited symbol rejected')

    ! Untyped CHARACTER length agreement versus typed CHARACTER conversion.
    q=constant_body
    new=q%expressions(root)%args(1)
    q%expressions(new)=expr_t(kind=ex_literal,typ=ty_character,character_len=2, &
        value=value_t(tag=ty_character,s='ab'))
    q%expressions(root)%typ=ty_character;q%expressions(root)%character_len=2
    call expect(valid_constructor_do(q,root),'matching untyped CHARACTER lengths accepted')
    q%expressions(root)%character_len=3
    call reject_tree(q,root,'untyped CHARACTER body length mismatch rejected')
    q%expressions(root)%op='character'
    call expect(valid_constructor_do(q,root),'typed CHARACTER explicit length permits padding')
    q%expressions(root)%character_len=-1
    call reject_tree(q,root,'typed CHARACTER requires nonnegative explicit length')
    q%expressions(root)%character_len=65537
    call reject_tree(q,root,'typed CHARACTER explicit length limit enforced')

    write(error_unit,'(a,i0,a)') 'constructor implied-DO source-free guards: ',checks,' checks passed'
contains
    subroutine expect(ok,text)
        logical,intent(in) :: ok
        character(*),intent(in) :: text
        checks=checks+1
        if(ok) return
        write(error_unit,*) 'FAIL ',checks,which,': ',text
        if(allocated(d%message)) write(error_unit,*) d%message
        error stop 1
    end subroutine
    subroutine reject_tree(program,index,text)
        type(program_t),intent(in) :: program
        integer,intent(in) :: index
        character(*),intent(in) :: text
        call expect(.not.valid_constructor_do(program,index),text//' / public do-tree gate')
        call expect(.not.valid_constructor_tree(program,wrapper),text//' / public whole-constructor gate')
        d=diagnostic_t();call execute_program(program,d)
        call expect(d%code==2,text//' / independent direct runtime')
        call expect(allocated(d%message),text//' / diagnostic allocated')
        if(allocated(d%message)) call expect(len_trim(d%message)>0,text//' / diagnostic nonempty')
    end subroutine
    subroutine append_expr(program,expression,index)
        type(program_t),intent(inout) :: program
        type(expr_t),intent(in) :: expression
        integer,intent(out) :: index
        call expect(program%ne<size(program%expressions),'mutation fits expression capacity')
        program%ne=program%ne+1;index=program%ne
        program%expressions(index)=expression
    end subroutine
    subroutine make_depth(levels,program,owners,indices,symbols)
        integer,intent(in) :: levels
        type(program_t),intent(out) :: program
        integer,intent(out) :: owners(9),indices(9),symbols(9)
        type(expr_t) :: node
        integer :: level,child
        program=p;owners=0;indices=0;symbols=0
        owners(1)=root;indices(1)=idx;symbols(1)=s
        do level=2,levels
            call expect(program%ns<size(program%symbols),'mutation fits symbol capacity')
            program%ns=program%ns+1;symbols(level)=program%ns
            program%symbols(symbols(level))=p%symbols(s)
            write(program%symbols(symbols(level))%name,'(a,i0)') 'native_index_',level
            node=p%expressions(root);node%symbol=symbols(level)
            call append_expr(program,node,owners(level))
            node=p%expressions(idx);node%symbol=symbols(level);node%constructor_owner=owners(level)
            call append_expr(program,node,indices(level))
        end do
        do level=1,levels
            child=indices(level)
            if(level<levels) child=owners(level+1)
            program%expressions(owners(level))%args=[child]
        end do
    end subroutine
end program
