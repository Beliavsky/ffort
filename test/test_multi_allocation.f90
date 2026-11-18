! SPDX-License-Identifier: MIT
! Multi-object operations are one validated statement, with left-to-right,
! prefix-preserving execution after a whole-group metadata/effect preflight.
program test_multi_allocation
    use, intrinsic :: iso_fortran_env, only: int64
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: execute_program
    implicit none
    character(*),parameter :: nl=new_line('a')
    type(program_t) :: p,q
    type(diagnostic_t) :: d
    character(:),allocatable :: source,label
    integer :: checks=0,j,head

    call numeric_baseline()
    call character_baselines()
    call prefix_baselines()
    call object_count_boundaries()
    call metadata_mutations()
    call descriptor_mutations()
    call character_mutations()
    call dependency_and_graph_checks()
    call frame_and_effect_checks()
    call preflight_precedence()
    print '(a,i0,a)','PASS: ',checks,' multi-object allocation checks'
contains
    subroutine numeric_baseline()
        source='program main'//nl// &
            'integer,allocatable::a(:),b(:,:),c(:,:,:)'//nl// &
            'real,allocatable::x(:),y(:,:)'//nl//'logical,allocatable::t(:),f(:)'//nl// &
            'integer::s'//nl//'s=-17'//nl// &
            'allocate(a(-1:1),b(2:3,0:2),c(1:2,1:2,-1:0),x(2),y(2,1),t(2),f(1),stat=s)'//nl// &
            'if(s/=0) error stop 1'//nl//'a=3'//nl//'b=4'//nl//'c=5'//nl// &
            'x=1.5'//nl//'y=2.5'//nl//'t=.true.'//nl//'f=.false.'//nl// &
            'if(sum(a)/=9.or.sum(b)/=24.or.c(1,1,-1)/=5.or.c(2,2,0)/=5) error stop 2'//nl// &
            'if(lbound(a,1)/=-1.or.lbound(b,2)/=0.or.lbound(c,3)/=-1) error stop 3'//nl// &
            'if(x(2)/=1.5.or.y(2,1)/=2.5.or..not.t(2).or.f(1)) error stop 4'//nl// &
            's=-18'//nl//'deallocate(a,b,c,x,y,t,f,stat=s)'//nl//'if(s/=0) error stop 5'//nl// &
            'if(allocated(a).or.allocated(b).or.allocated(c)) error stop 6'//nl// &
            'if(allocated(x).or.allocated(y).or.allocated(t).or.allocated(f)) error stop 7'//nl// &
            'end program'
        call baseline(source,'mixed intrinsic types and ranks')
        head=instruction_with(p,op_allocate)
        call expect(p%code(head)%c==7,'mixed allocation group count')
        call check_group(p,head,7)
        head=instruction_with(p,op_deallocate)
        call check_group(p,head,7)
        do j=1,3
            call run_ok(p,'fresh descriptor state on repeated execution')
        end do
        source='program main'//nl//'integer,allocatable::a(:)'//nl// &
            'allocate(a(2))'//nl//'deallocate(a)'//nl//'end program'
        call baseline(source,'single-object compatibility')
        do j=1,p%nc
            if(p%code(j)%op/=op_allocate.and.p%code(j)%op/=op_deallocate) cycle
            call expect(p%code(j)%c==0.and.p%code(j)%d==0.and.p%code(j)%target==0, &
                        'single-object metadata remains zero')
        end do
    end subroutine

    subroutine character_baselines()
        source='program main'//nl//'character(:),allocatable::a(:),b(:,:)'//nl// &
            'integer::n,s'//nl//'n=3'//nl//'s=-1'//nl// &
            'allocate(character(len=n+1)::a(-2:0),b(2,2),stat=s)'//nl// &
            'if(s/=0.or.len(a)/=4.or.len(b)/=4) error stop 1'//nl// &
            'a="abcdef"'//nl//'b="xy"'//nl// &
            'if(a(-2)/="abcd".or.b(2,2)/="xy  ") error stop 2'//nl// &
            'deallocate(a,b,stat=s)'//nl//'if(s/=0) error stop 3'//nl// &
            'allocate(character(0)::a(0),b(1,0))'//nl// &
            'if(len(a)/=0.or.len(b)/=0.or.size(a)/=0.or.size(b)/=0) error stop 4'//nl// &
            'deallocate(a,b)'//nl//'end program'
        call baseline(source,'shared deferred CHARACTER length, padding and zero extents')
        head=instruction_with(p,op_allocate)
        call expect(p%code(head)%b>0.and.p%code(head)%b==p%code(head+1)%b, &
                    'deferred CHARACTER group shares one length root')
        source='program main'//nl//'character(3),allocatable::a(:),b(:)'//nl// &
            'allocate(a(2),b(-1:0))'//nl//'a="hello"'//nl//'b="q"'//nl// &
            'if(len(a)/=3.or.len(b)/=3.or.a(1)/="hel".or.b(-1)/="q  ") error stop 1'//nl// &
            'deallocate(a,b)'//nl//'end program'
        call baseline(source,'fixed-length CHARACTER group')
    end subroutine

    subroutine prefix_baselines()
        character(1),parameter :: names(3)=['a','b','c']
        character(:),allocatable :: text
        integer :: failure,pos
        do failure=1,3
            text='program main'//nl//'integer,allocatable::a(:),b(:),c(:)'//nl// &
                'integer::s'//nl//'allocate('//names(failure)//'(1))'//nl// &
                names(failure)//'=91'//nl//'s=-99'//nl// &
                'allocate(a(2),b(3),c(4),stat=s)'//nl//'if(s<=0) error stop 1'//nl// &
                'if('//names(failure)//'(1)/=91) error stop 2'//nl
            do pos=1,3
                if(pos<=failure) then
                    text=text//'if(.not.allocated('//names(pos)//')) error stop 3'//nl
                    if(pos<failure) text=text//'if(size('//names(pos)//')/='//number(pos+1)// &
                        ') error stop 4'//nl
                else
                    text=text//'if(allocated('//names(pos)//')) error stop 5'//nl
                end if
            end do
            text=text//'end program'
            call baseline(text,'ALLOCATE failure at object '//number(failure)//' preserves prefix')
            text='program main'//nl//'integer,allocatable::a(:),b(:),c(:)'//nl// &
                'integer::s'//nl//'allocate(a(2),b(3),c(4),stat=s)'//nl// &
                'if(s/=0) error stop 1'//nl//'a=11'//nl//'b=22'//nl//'c=33'//nl// &
                'deallocate('//names(failure)//')'//nl//'s=-99'//nl// &
                'deallocate(a,b,c,stat=s)'//nl//'if(s<=0) error stop 2'//nl
            do pos=1,3
                if(pos<=failure) then
                    text=text//'if(allocated('//names(pos)//')) error stop 3'//nl
                else
                    text=text//'if(.not.allocated('//names(pos)//')) error stop 4'//nl// &
                        'if('//names(pos)//'(1)/='//number(11*pos)//') error stop 5'//nl
                end if
            end do
            text=text//'end program'
            call baseline(text,'DEALLOCATE failure at object '//number(failure)//' preserves suffix')
        end do
        text='program main'//nl//'integer,allocatable::a(:),b(:),c(:)'//nl//'integer::s'//nl// &
            'allocate(a(2),b('//number(max_array_elements)//'),c(1),stat=s)'//nl//'if(s<=0) error stop 1'//nl// &
            'if(.not.allocated(a).or.allocated(b).or.allocated(c)) error stop 2'//nl// &
            'deallocate(a)'//nl//'end program'
        call baseline(text,'capacity failure also preserves successful allocation prefix')
        text='program main'//nl//'integer,allocatable::a(:),b(:)'//nl// &
            'allocate(b(1))'//nl//'allocate(a(2),b(2))'//nl//'end program'
        call fresh(text)
        call verify_ok(text,p,'failure without STAT is statically valid')
        d=diagnostic_t();call execute_program(p,d)
        call expect(d%code==2,'ALLOCATE failure without STAT is a runtime error')
        call message_has('already allocated','ALLOCATE failure diagnostic')
        text='program main'//nl//'integer,allocatable::a(:),b(:)'//nl// &
            'allocate(a(1))'//nl//'deallocate(a,b)'//nl//'end program'
        call fresh(text)
        call verify_ok(text,p,'DEALLOCATE failure without STAT is statically valid')
        d=diagnostic_t();call execute_program(p,d)
        call expect(d%code==2,'DEALLOCATE failure without STAT is a runtime error')
        call message_has('not allocated','DEALLOCATE failure diagnostic')
    end subroutine

    subroutine object_count_boundaries()
        character(:),allocatable :: text,objects,bounds
        integer :: count,pos
        do count=2,65,63
            text='program main'//nl;objects='';bounds=''
            do pos=1,count
                text=text//'integer,allocatable::a'//number(pos)//'(:)'//nl
                if(pos>1) then
                    if(mod(pos-1,8)==0) then
                        objects=objects//', &'//nl;bounds=bounds//', &'//nl
                    else
                        objects=objects//',';bounds=bounds//','
                    end if
                end if
                objects=objects//'a'//number(pos)
                bounds=bounds//'a'//number(pos)//'(0)'
            end do
            text=text//'allocate('//bounds//')'//nl//'deallocate('//objects//')'//nl//'end program'
            if(count<=max_allocation_objects) then
                call baseline(text,'minimum grouped object count')
            else
                d=diagnostic_t();call parse_subset(text,p,d)
                call expect(d%code==1,'65-object group exceeds the bounded subset')
            end if
        end do
        text='program main'//nl;objects='';bounds=''
        do pos=1,max_allocation_objects
            text=text//'integer,allocatable::a'//number(pos)//'(:)'//nl
            if(pos>1) then
                if(mod(pos-1,8)==0) then
                    objects=objects//', &'//nl;bounds=bounds//', &'//nl
                else
                    objects=objects//',';bounds=bounds//','
                end if
            end if
            objects=objects//'a'//number(pos)
            bounds=bounds//'a'//number(pos)//'(0)'
        end do
        text=text//'allocate('//bounds//')'//nl//'deallocate('//objects//')'//nl//'end program'
        call baseline(text,'64-object maximum allocation and deallocation')
        head=instruction_with(p,op_allocate)
        call check_group(p,head,max_allocation_objects)
    end subroutine

    subroutine metadata_mutations()
        integer :: operation,case_number,h,last
        source=integer_fixture()
        call baseline(source,'metadata mutation fixture')
        do operation=op_allocate,op_deallocate
            h=instruction_with(p,operation);last=h+2
            do case_number=1,33
                q=p
                label='group metadata '//number(operation)//' case '//number(case_number)
                select case(case_number)
                case(1);q%code(h)%c=1
                case(2);q%code(h)%c=max_allocation_objects+1
                case(3);q%code(h)%c=-1
                case(4);q%code(h)%d=2
                case(5);q%code(h)%target=h+2
                case(6);q%code(last)%c=2
                case(7);q%code(last)%d=1
                case(8);q%code(last)%target=h+4
                case(9);q%code(last)%a=0
                case(10);q%code(last)%b=p%ne+1
                case(11);q%code(last)%line=q%code(last)%line+1
                case(12);q%code(last)%column=q%code(last)%column+1
                case(13);q%code(last)%scope=1
                case(14);q%code(last)%op=op_assign
                case(15);q%code(last)%symbol=q%code(h)%symbol
                case(16);q%code(last)%symbol=0
                case(17);q%code(last)%symbol=p%ns+1
                case(18);q%code(last)%component=1
                case(19);q%code(last)%generic_id=1
                case(20);q%code(last)%third=1
                case(21);q%code(last)%bound_type=1
                case(22);q%code(last)%bound_binding=1
                case(23);q%code(last)%construct_name='forged'
                case(24);q%code(last)%format=''
                case(25);deallocate(q%code(last)%items)
                case(26);q%code(last)%items=[q%code(last)%items,0]
                case(27);q%code(h)%a=-1
                case(28);q%code(h)%a=p%ne+1
                case(29);q%code(last)%c=0;q%code(last)%d=0;q%code(last)%target=0
                case(30);q%code(h)%target=huge(0)
                case(31);q%code(h)%d=huge(0)
                case(32);q%code(h)%c=huge(0)
                case(33);q%code(h)%c=0;q%code(h)%d=1
                end select
                call expect(.not.valid_allocation_group(q,h),label//' gate')
                call rejected(source,q,label)
            end do
        end do
        ! The adapter must also reject removal of every group marker. The
        ! runtime is allowed to interpret these as ordinary single operations.
        q=p;h=instruction_with(q,op_allocate)
        q%code(h:h+2)%c=0;q%code(h:h+2)%d=0;q%code(h:h+2)%target=0
        d=diagnostic_t();call verify_frontend(source,q,d)
        call expect(d%code==1,'adapter rejects a multi-object statement split into singles')
    end subroutine

    subroutine descriptor_mutations()
        integer :: case_number,h,last,target,stat_root,bound
        source=integer_fixture()
        call baseline(source,'descriptor mutation fixture')
        h=instruction_with(p,op_allocate);last=h+2
        target=p%code(last)%symbol;stat_root=p%code(h)%a;bound=p%code(last)%items(2)
        do case_number=1,25
            q=p
            label='descriptor case '//number(case_number)
            select case(case_number)
            case(1);q%symbols(target)%is_allocatable=.false.
            case(2);q%symbols(target)%is_pointer=.true.
            case(3);q%symbols(target)%is_parameter=.true.
            case(4);q%symbols(target)%rank=0
            case(5);q%symbols(target)%rank=4
            case(6);q%symbols(target)%rank=2
            case(7);q%symbols(target)%dummy_intent=1
            case(8);q%symbols(target)%assumed_shape=.true.
            case(9);q%symbols(target)%is_automatic=.true.
            case(10);q%symbols(target)%typ=0
            case(11);q%symbols(target)%lower_bound=2_int64
            case(12);q%code(last)%items(2)=0
            case(13);q%code(last)%items(2)=p%ne+1
            case(14);q%code(last)%items(1)=-1
            case(15);q%expressions(bound)%typ=ty_real
            case(16);q%expressions(bound)%rank=1
            case(17);q%expressions(bound)%real_kind=16
            case(18);q%expressions(stat_root)%parenthesized=.true.
            case(19);q%expressions(stat_root)%kind=ex_binary
            case(20);q%expressions(stat_root)%symbol=0
            case(21);q%expressions(stat_root)%symbol=p%ns+1
            case(22);q%symbols(p%expressions(stat_root)%symbol)%typ=ty_real
            case(23);q%symbols(p%expressions(stat_root)%symbol)%rank=1
            case(24);q%symbols(p%expressions(stat_root)%symbol)%dummy_intent=1
            case(25);q%expressions(stat_root)%rank=1
            end select
            call rejected(source,q,label)
        end do
    end subroutine

    subroutine character_mutations()
        integer :: case_number,h,target,length_root
        source='program main'//nl//'character(:),allocatable::a(:),b(:)'//nl//'integer::s,n'//nl// &
            'n=3'//nl//'allocate(character(n)::a(2),b(2),stat=s)'//nl//'deallocate(a,b)'//nl//'end program'
        call baseline(source,'CHARACTER mutation fixture')
        h=instruction_with(p,op_allocate);target=p%code(h+1)%symbol;length_root=p%code(h)%b
        do case_number=1,10
            q=p
            label='CHARACTER group case '//number(case_number)
            select case(case_number)
            case(1);q%code(h+1)%b=0
            case(2);q%code(h:h+1)%b=0
            case(3);q%code(h:h+1)%b=p%ne+1
            case(4);q%expressions(length_root)%typ=ty_real
            case(5);q%expressions(length_root)%rank=1
            case(6);q%symbols(target)%deferred_character=.false.
            case(7);q%symbols(target)%character_len=3
            case(8);q%symbols(target)%length_expr=length_root
            case(9);q%expressions(length_root)%left=length_root
            case(10)
                q%expressions(length_root)%symbol=q%expressions(p%code(h)%a)%symbol
            end select
            call rejected(source,q,label)
        end do
    end subroutine

    subroutine dependency_and_graph_checks()
        integer :: case_number,h,bound,node,child,depth
        type(expr_t) :: x
        source='program main'//nl//'integer,allocatable::a(:),b(:),c(:)'//nl//'integer::n,s'//nl// &
            'n=2'//nl//'allocate(a(n+n),b(n+n),c(n+n),stat=s)'//nl// &
            'if(s/=0.or.size(a)/=4.or.size(b)/=4.or.size(c)/=4) error stop 1'//nl// &
            'deallocate(a,b,c)'//nl//'end program'
        call baseline(source,'bound DAG fixture')
        h=instruction_with(p,op_allocate);bound=p%code(h+2)%items(2)
        q=p
        q%code(h+1)%items(2)=p%code(h)%items(2)
        q%code(h+2)%items(2)=p%code(h)%items(2)
        call expect(valid_allocation_group(q,h),'shared sibling bound root accepted')
        call verify_ok(source,q,'adapter accepts shared equivalent expression root')
        call run_ok(q,'runtime accepts shared equivalent expression root')
        do case_number=1,18
            q=p
            label='bound dependency or graph case '//number(case_number)
            child=q%expressions(bound)%left
            select case(case_number)
            case(1);q%expressions(child)%symbol=q%code(h)%symbol
            case(2);q%expressions(child)%symbol=q%code(h+1)%symbol
            case(3);q%expressions(child)%symbol=q%code(h+2)%symbol
            case(4);q%expressions(child)%symbol=q%expressions(q%code(h)%a)%symbol
            case(5);q%expressions(child)%kind=ex_user_call
            case(6);q%expressions(bound)%left=bound
            case(7);q%expressions(child)%left=bound
            case(8);q%expressions(bound)%left=q%ne+1
            case(9);q%expressions(bound)%right=-1
            case(10);q%expressions(bound)%stride=bound
            case(11);q%expressions(bound)%left2=bound
            case(12);q%expressions(bound)%right2=bound
            case(13);q%expressions(bound)%stride2=bound
            case(14);q%expressions(bound)%left3=bound
            case(15);q%expressions(bound)%right3=bound
            case(16);q%expressions(bound)%stride3=bound
            case(17);q%expressions(bound)%third=bound
            case(18);q%expressions(bound)%args=[bound]
            end select
            call expect(.not.valid_allocation_group(q,h),label//' gate')
            call rejected(source,q,label)
        end do
        ! A bounded DAG may share both children at every level. The group gate
        ! must visit each node once rather than recurse exponentially.
        q=p;node=q%code(h)%items(2)
        do depth=1,400
            x=expr_t(kind=ex_binary,typ=ty_integer,left=node,right=node,op='+')
            node=append_expression(q,x)
        end do
        q%code(h+2)%items(2)=node
        call expect(valid_allocation_group(q,h),'400-level shared DAG gate is linear and accepted')
        ! A chain over the explicit depth bound is invalid even without a cycle.
        do depth=401,520
            x=expr_t(kind=ex_binary,typ=ty_integer,left=node,right=node,op='+')
            node=append_expression(q,x)
        end do
        q%code(h+2)%items(2)=node
        call expect(.not.valid_allocation_group(q,h),'excessive acyclic DAG depth rejected')
        call rejected(source,q,'excessive bound DAG depth')
        ! Source restrictions are explicit subset boundaries, including inquiries
        ! that would otherwise observe an earlier member's newly changed state.
        do case_number=1,3
            select case(case_number)
            case(1);label='size(a)'
            case(2);label='s'
            case(3);label='f()'
            end select
            source='module m'//nl//'contains'//nl//'integer function f()'//nl//'f=2'//nl// &
                'end function'//nl//'end module'//nl//'program main'//nl//'use m'//nl// &
                'integer,allocatable::a(:),b(:)'//nl//'integer::s'//nl//'s=2'//nl// &
                'allocate(a(2),b('//label//'),stat=s)'//nl//'end program'
            d=diagnostic_t();call parse_subset(source,q,d)
            call expect(d%code==1,'source rejects bound dependency '//label)
        end do
    end subroutine

    subroutine frame_and_effect_checks()
        integer :: h,case_number
        source='module m'//nl//'contains'//nl//'subroutine work()'//nl// &
            'integer,allocatable::a(:),b(:)'//nl//'allocate(a(2),b(3))'//nl// &
            'deallocate(a,b)'//nl//'end subroutine'//nl//'end module'//nl// &
            'program main'//nl//'use m'//nl//'call work()'//nl//'end program'
        call baseline(source,'procedure-frame group fixture')
        h=instruction_with(p,op_allocate)
        do case_number=1,3
            q=p
            select case(case_number)
            case(1)
                q%procedures(1)%last=h
                label='group crosses procedure frame end'
            case(2)
                q%procedures(1)%first=h+1
                label='procedure starts in middle of allocation group'
            case(3)
                q%code(h:h+1)%scope=0
                label='group instructions outside active procedure scope'
            end select
            call rejected(source,q,label)
        end do
        source=integer_fixture()
        call baseline(source,'main-entry group fixture')
        q=p;h=instruction_with(q,op_allocate);q%entry_pc=h+1
        call rejected(source,q,'main entry in middle of allocation group')
        ! Honest source has a local first target and a module second target.
        ! Alter only the procedure purity metadata to exercise the runtime guard
        ! independently of the parser/adapter effect analysis.
        source='module m'//nl//'integer,allocatable::shared(:)'//nl//'contains'//nl// &
            'subroutine work()'//nl//'integer,allocatable::local(:)'//nl// &
            'integer::n'//nl//'n=0'//nl//'allocate(local(1/n),shared(2))'//nl// &
            'end subroutine'//nl//'end module'//nl//'program main'//nl//'use m'//nl// &
            'call work()'//nl//'end program'
        call fresh(source)
        call verify_ok(source,p,'second-object module-effect fixture')
        q=p;q%procedures(1)%is_pure=.true.
        d=diagnostic_t();call verify_frontend(source,q,d)
        call expect(d%code==1,'adapter rejects forged purity with module group member')
        d=diagnostic_t();call execute_program(q,d)
        call expect(d%code==2,'runtime checks module effect on second group member')
        call message_has('external side effect','second-object effect preflight precedes first bound evaluation')
        ! The same guard must run for DEALLOCATE, even if the first local target
        ! is already unallocated and would otherwise terminate execution first.
        source='module m'//nl//'integer,allocatable::shared(:)'//nl//'contains'//nl// &
            'subroutine work()'//nl//'integer,allocatable::local(:)'//nl// &
            'deallocate(local,shared)'//nl//'end subroutine'//nl//'end module'//nl// &
            'program main'//nl//'use m'//nl//'call work()'//nl//'end program'
        call fresh(source)
        call verify_ok(source,p,'second-object deallocation effect fixture')
        q=p;q%procedures(1)%is_pure=.true.
        d=diagnostic_t();call execute_program(q,d)
        call expect(d%code==2,'runtime checks second DEALLOCATE module effect')
        call message_has('external side effect','deallocation effect preflight precedes allocation-state error')
    end subroutine

    subroutine preflight_precedence()
        integer :: h,bound
        source='program main'//nl//'integer,allocatable::a(:),b(:)'//nl//'integer::n,s'//nl// &
            'n=0'//nl//'allocate(a(1/n),b(2),stat=s)'//nl//'end program'
        call fresh(source)
        call verify_ok(source,p,'metadata preflight precedence fixture')
        h=instruction_with(p,op_allocate)
        q=p;q%code(h+1)%items(2)=0
        d=diagnostic_t();call execute_program(q,d)
        call expect(d%code==2,'malformed later bound is not swallowed by STAT')
        call message_has('allocation group','whole-group structure preflight precedes first-object divide by zero')
        q=p;bound=q%code(h+1)%items(2);q%expressions(bound)%typ=ty_real
        d=diagnostic_t();call execute_program(q,d)
        call expect(d%code==2,'malformed later operand type is not swallowed by STAT')
        call expect(index(d%message,'division')==0.and.index(d%message,'zero')==0, &
                    'all operand types checked before first-object arithmetic')
    end subroutine

    function integer_fixture() result(text)
        character(:),allocatable :: text
        text='program main'//nl//'integer,allocatable::a(:),b(:),c(:)'//nl//'integer::s,n'//nl// &
            'n=2'//nl//'allocate(a(n),b(n+1),c(n+2),stat=s)'//nl// &
            'if(s/=0) error stop 1'//nl//'deallocate(a,b,c,stat=s)'//nl// &
            'if(s/=0) error stop 2'//nl//'end program'
    end function

    subroutine check_group(prog,h,n)
        type(program_t),intent(in) :: prog
        integer,intent(in) :: h,n
        integer :: pos
        call expect(valid_allocation_group(prog,h),'honest group validator')
        do pos=1,n
            call expect(prog%code(h+pos-1)%c==n.and.prog%code(h+pos-1)%d==pos.and. &
                        prog%code(h+pos-1)%target==h+n,'group count, ordinal and end')
            call expect(prog%code(h+pos-1)%a==prog%code(h)%a.and. &
                        prog%code(h+pos-1)%b==prog%code(h)%b,'group shared operand identity')
        end do
    end subroutine

    subroutine fresh(text)
        character(*),intent(in) :: text
        d=diagnostic_t();call parse_subset(text,p,d)
        call expect(d%code==0,'parse fixture')
    end subroutine

    subroutine baseline(text,name)
        character(*),intent(in) :: text,name
        call fresh(text)
        call verify_ok(text,p,name//' adapter')
        call run_ok(p,name//' execution')
    end subroutine

    subroutine verify_ok(text,prog,name)
        character(*),intent(in) :: text,name
        type(program_t),intent(in) :: prog
        d=diagnostic_t();call verify_frontend(text,prog,d)
        call expect(d%code==0,name)
    end subroutine

    subroutine run_ok(prog,name)
        type(program_t),intent(in) :: prog
        character(*),intent(in) :: name
        d=diagnostic_t();call execute_program(prog,d)
        call expect(d%code==0,name)
    end subroutine

    subroutine rejected(text,prog,name)
        character(*),intent(in) :: text,name
        type(program_t),intent(in) :: prog
        d=diagnostic_t();call verify_frontend(text,prog,d)
        call expect(d%code==1,name//' adapter rejects')
        d=diagnostic_t();call execute_program(prog,d)
        call expect(d%code==2,name//' direct runtime rejects')
    end subroutine

    integer function instruction_with(prog,operation) result(found)
        type(program_t),intent(in) :: prog
        integer,intent(in) :: operation
        integer :: pos
        found=0
        do pos=1,prog%nc
            if(prog%code(pos)%op/=operation) cycle
            found=pos;return
        end do
        call expect(.false.,'fixture instruction exists')
    end function

    integer function append_expression(prog,x) result(found)
        type(program_t),intent(inout) :: prog
        type(expr_t),intent(in) :: x
        type(expr_t),allocatable :: grown(:)
        if(prog%ne==size(prog%expressions)) then
            allocate(grown(prog%ne+1))
            grown(:prog%ne)=prog%expressions
            call move_alloc(grown,prog%expressions)
        end if
        prog%ne=prog%ne+1;found=prog%ne;prog%expressions(found)=x
    end function

    function number(value) result(text)
        integer,intent(in) :: value
        character(:),allocatable :: text
        character(32) :: buffer
        write(buffer,'(i0)') value
        text=trim(buffer)
    end function

    subroutine message_has(fragment,name)
        character(*),intent(in) :: fragment,name
        call expect(allocated(d%message),name//' diagnostic exists')
        call expect(index(d%message,fragment)>0,name)
    end subroutine

    subroutine expect(ok,name)
        logical,intent(in) :: ok
        character(*),intent(in) :: name
        checks=checks+1
        if(ok) return
        print '(a)',trim(name)
        print '(a,i0)','diagnostic code: ',d%code
        if(allocated(d%message)) print '(a)',d%message
        error stop 1
    end subroutine
end program
