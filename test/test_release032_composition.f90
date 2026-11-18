! SPDX-License-Identifier: MIT
! Independent synthetic POINTER/explicit-bound composition. No original utility code.
! Every corrupt IR starts from a fresh parsed and successfully executed baseline.
program test_release032_composition
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program main'//nl//'implicit none'//nl// &
        'integer,target::a(6)'//nl//'integer,pointer::p(:),q(:)'//nl// &
        'a=[1,2,3,4,5,6]'//nl//'p=>a'//nl//'call expose(a,q)'//nl// &
        'call fill(a,3,q)'//nl//'if(any(p/=[11,12,13,4,5,6])) error stop 1'//nl// &
        'q(6)=60'//nl//'if(a(6)/=60) error stop 2'//nl// &
        'if(any(findloc(p,13)/=[3])) error stop 3'//nl// &
        'if(any(shape(p)/=[6])) error stop 4'//nl// &
        'nullify(p)'//nl//'nullify(q)'//nl// &
        'contains'//nl//'subroutine fill(x,n,descriptor)'//nl//'integer,intent(in)::n'//nl// &
        'integer,target,intent(inout)::x(0:n-1)'//nl// &
        'integer,pointer,optional,intent(in)::descriptor(:)'//nl// &
        'if(.not.present(descriptor)) error stop 5'//nl// &
        'if(.not.associated(descriptor)) error stop 6'//nl//'x=x+10'//nl//'end subroutine'//nl// &
        'subroutine expose(backing,view)'//nl//'integer,target,intent(inout)::backing(:)'//nl// &
        'integer,pointer,intent(out)::view(:)'//nl//'view=>backing'//nl//'end subroutine'//nl//'end program'
    character(*),parameter::tail_source='program main'//nl//'implicit none'//nl// &
        'integer,target::a(6)'//nl//'integer,pointer::p(:)'//nl//'a(1:5)=9'//nl// &
        'p=>a'//nl//'call fill(a,3)'//nl//'if(p(6)==9) stop'//nl// &
        'contains'//nl//'subroutine fill(x,n)'//nl//'integer,intent(in)::n'//nl// &
        'integer,target,intent(out)::x(n)'//nl//'x=7'//nl//'end subroutine'//nl//'end program'
    type(program_t)::p
    type(diagnostic_t)::d
    integer::mutation,j,xsym,psym,vsym,dsym,asym,root,pc,assoc_expr,checks
    checks=0
    do mutation=1,16
        call fresh()
        xsym=0;psym=0;vsym=0;dsym=0;asym=0;pc=0
        do j=1,p%ns
            select case(p%symbols(j)%name)
            case('x');xsym=j
            case('p');psym=j
            case('view');vsym=j
            case('descriptor');dsym=j
            case('a');asym=j
            end select
        end do
        do j=1,p%nc
            if(p%code(j)%op==op_pointer_assign.and.p%code(j)%symbol==psym) pc=j
        end do
        call expect(min(xsym,psym,vsym,dsym,asym,pc)>0,'composition symbols and association present')
        root=p%symbols(xsym)%upper_expr
        assoc_expr=p%code(pc)%a
        call expect(root>0.and.assoc_expr>0,'explicit bound and association metadata present')
        select case(mutation)
        case(1);p%symbols(xsym)%is_optional=.true.
        case(2);p%symbols(xsym)%upper_expr=0
        case(3);p%symbols(xsym)%assumed_shape=.true.
        case(4);p%symbols(xsym)%is_pointer=.true.
        case(5);p%symbols(vsym)%is_automatic=.true.
        case(6);p%symbols(psym)%rank=2
        case(7);p%symbols(psym)%is_allocatable=.true.
        case(8);p%symbols(asym)%is_target=.false.
        case(9);p%expressions(root)%typ=ty_real
        case(10);p%expressions(root)%left=root
        case(11);p%expressions(assoc_expr)%parenthesized=.true.
        case(12);p%code(pc)%b=assoc_expr
        case(13);p%symbols(dsym)%lower_expr=root
        case(14);p%symbols(vsym)%dummy_intent=0
        case(15);p%symbols(vsym)%is_target=.true.
        case(16);p%symbols(xsym)%upper_expr=p%ne+1
        end select
        d=diagnostic_t()
        call verify_frontend(source,p,d)
        call expect(d%code==1,'independent adapter rejects corrupt composition')
        d=diagnostic_t()
        call execute_program(p,d)
        call expect(d%code==2,'direct runtime rejects corrupt composition')
        call expect(allocated(d%message),'runtime rejection has diagnostic')
        call expect(index(d%message,'STOP')==0,'runtime validation rather than user ERROR STOP')
        checks=checks+2
    end do
    call fresh()
    do j=1,3
        d=diagnostic_t()
        call execute_program(p,d)
        call expect(d%code==0,'repeat execution restores view and explicit-dummy state')
    end do
    d=diagnostic_t()
    call parse_subset(tail_source,p,d)
    call expect(d%code==0,'undefined unused actual tail parser')
    call verify_frontend(tail_source,p,d)
    call expect(d%code==0,'undefined unused actual tail adapter')
    call execute_program(p,d)
    call expect(d%code==2,'undefined unused actual tail is not initialized by copyback')
    call expect(allocated(d%message),'undefined tail has diagnostic')
    call expect(index(d%message,'uninitialized')>0,'undefined tail reports definition-state guard')
    print '(a,i0,a)','PASS: release 0.32 composition and ',checks,' adapter/runtime metadata rejections; undefined-tail guard'
contains
    subroutine fresh()
        d=diagnostic_t()
        call parse_subset(source,p,d)
        call expect(d%code==0,'honest composition parser')
        call verify_frontend(source,p,d)
        call expect(d%code==0,'honest composition adapter')
        call execute_program(p,d)
        call expect(d%code==0,'honest composition runtime')
    end subroutine
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        if(ok)return
        print *,label,' mutation=',mutation,' code=',d%code
        if(allocated(d%message)) print *,d%message
        error stop 1
    end subroutine
end program
