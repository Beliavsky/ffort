! SPDX-License-Identifier: MIT
program test_nested_procedures
    use, intrinsic::iso_fortran_env,only:int64
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    type(value_t)::empty_arguments(0)
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='module m'//nl//'implicit none'//nl//'contains'//nl// &
        'subroutine host(a,n,total)'//nl//'integer,intent(inout)::a(:)'//nl// &
        'integer,intent(in)::n'//nl//'integer,intent(out)::total'//nl//'integer::state'//nl// &
        'state=0'//nl//'call descend(n)'//nl//'call sibling()'//nl//'total=state+sum(a)'//nl// &
        'contains'//nl//'recursive subroutine descend(k)'//nl//'integer,intent(in)::k'//nl// &
        'integer::local'//nl//'local=k'//nl//'if(k>0) call descend(k-1)'//nl// &
        'state=state+local'//nl//'a=a+local'//nl//'call sibling()'//nl//'end subroutine'//nl// &
        'subroutine sibling()'//nl//'state=state+1'//nl//'end subroutine'//nl//'end subroutine'//nl// &
        'subroutine outsider(x)'//nl//'integer,intent(inout)::x'//nl//'x=x+1'//nl// &
        'end subroutine'//nl//'end module'//nl//'program main'//nl//'use m'//nl//'implicit none'//nl// &
        'integer::a(3),total'//nl//'a=[1,2,3]'//nl//'call host(a,3,total)'//nl// &
        'if(any(a/=[7,8,9])) error stop 1'//nl//'if(total/=35) error stop 2'//nl// &
        'call host(a,1,total)'//nl//'if(any(a/=[8,9,10])) error stop 3'//nl// &
        'if(total/=31) error stop 4'//nl//'call outsider(total)'//nl// &
        'if(total/=32) error stop 5'//nl//'end program'
    integer::stage,which,j,host,child,sibling,outsider,scalar,array,dummy,main_call,checks
    integer::main_scalar,child_read,child_write,second_call
    integer(int64)::budget
    checks=0
    call baseline()
    call expect(valid_internal_procedure(p,host),'ordinary module host is structurally valid')
    call expect(valid_internal_procedure(p,child),'internal child is structurally valid')
    call expect(valid_internal_procedure(p,sibling),'internal sibling is structurally valid')
    call expect(.not.valid_internal_procedure(p,0),'zero procedure index is invalid')
    call expect(.not.valid_internal_procedure(p,p%np+1),'past-end procedure index is invalid')
    call expect(host_symbol_visible(p,scalar,child),'ordinary host scalar is capturable')
    call expect(host_symbol_visible(p,array,child),'ordinary assumed-shape host array is capturable')
    call expect(host_symbol_visible(p,scalar,sibling),'sibling sees the same host scalar')
    call expect(.not.host_symbol_visible(p,scalar,outsider),'unrelated procedure cannot capture scalar')
    call expect(.not.host_symbol_visible(p,scalar,host),'host is not its own internal parent')
    call expect(.not.host_symbol_visible(p,0,child),'zero symbol index is invalid')
    call expect(.not.host_symbol_visible(p,p%ns+1,child),'past-end symbol index is invalid')
    call expect(internal_call_visible(p,host,child),'host may call its child')
    call expect(internal_call_visible(p,child,child),'internal recursion remains lexically visible')
    call expect(internal_call_visible(p,child,sibling),'child may call sibling')
    call expect(internal_call_visible(p,sibling,child),'sibling may call child')
    call expect(internal_call_visible(p,child,host),'internal procedure may call defining host')
    call expect(.not.internal_call_visible(p,0,child),'main cannot directly call internal child')
    call expect(.not.internal_call_visible(p,outsider,child),'unrelated module procedure cannot call child')
    call expect(.not.internal_call_visible(p,p%np+1,child),'invalid caller cannot call child')
    call expect(.not.internal_call_visible(p,host,p%np+1),'invalid callee cannot be called')
    ! Every corruption must be rejected by source/IR cross-validation and by
    ! runtime guards independently. No exact diagnostic text is assumed.
    do stage=1,2
        do which=1,38
            call baseline()
            select case(which)
            case(2);p%procedures(child)%parent_procedure=0
            case(3);p%procedures(child)%parent_procedure=-1
            case(4);p%procedures(child)%parent_procedure=p%np+1
            case(5);p%procedures(child)%parent_procedure=child
            case(6);p%procedures(child)%parent_procedure=sibling
            case(7);p%procedures(host)%parent_procedure=child
            case(8);p%procedures(child)%is_public=.true.
            case(9);p%procedures(child)%module_id=0
            case(10);p%procedures(child)%module_id=p%nm+1
            case(11);p%procedures(host)%module_id=0
            case(12);p%procedures(host)%is_elemental=.true.
            case(13);p%procedures(child)%line=p%procedures(host)%line
            case(14);p%procedures(child)%end_line=p%procedures(host)%end_line
            case(15);p%procedures(host)%end_line=p%procedures(child)%end_line
            case(16)
                p%code(main_call)%symbol=sibling
                deallocate(p%code(main_call)%items)
                allocate(p%code(main_call)%items(0))
            case(17);p%symbols(scalar)%is_optional=.true.
            case(18);p%symbols(scalar)%is_pointer=.true.
            case(19);p%symbols(scalar)%is_target=.true.
            case(20);p%symbols(array)%is_allocatable=.true.
            case(21);p%symbols(scalar)%typ=ty_derived_base+1
            case(22);p%symbols(scalar)%is_class=.true.
            case(23);p%symbols(scalar)%scope=0
            case(24);p%symbols(scalar)%scope=outsider
            case(25);p%symbols(array)%dummy_intent=1
            case(26);p%symbols(array)%is_dummy=.false.
            case(27);p%procedures(child)%is_pure=.true.
            case(28);p%procedures(child)%is_pure=.true.;p%procedures(child)%is_simple=.true.
            case(29);p%procedures(host)%result_symbol=scalar
            case(30);p%symbols(scalar)%deferred_character=.true.
            case(31);p%symbols(scalar)%rank=4
            case(32);p%procedures(child)%is_recursive=.false.
            case(33);p%symbols(dummy)%dummy_intent=2
            case(34);p%symbols(scalar)%is_allocatable=.true.
            case(35);p%symbols(array)%is_target=.true.
            case(36);p%expressions(child_read)%symbol=main_scalar
            case(37);p%code(child_write)%symbol=main_scalar
            case(38)
                ! The first host call has returned before this forged call.
                p%code(second_call)%symbol=sibling
                deallocate(p%code(second_call)%items)
                allocate(p%code(second_call)%items(0))
            end select
            if(stage==1) then
                call verify_frontend(source,p,d)
            else
                call execute_program(p,d,max_steps=5000_int64)
            end if
            checks=checks+1
            if((which==1.and.d%code/=0).or.(which/=1.and.d%code/=stage)) then
                print *,stage,which,d%code
                if(allocated(d%message)) print *,d%message
                error stop 'internal procedure mutation expectation failed'
            end if
            if(which/=1) then
                if(.not.allocated(d%message)) error stop 'mutation rejection lacks diagnostic'
                if(len_trim(d%message)==0) error stop 'mutation rejection has empty diagnostic'
                ! ERROR STOP from a changed numeric result is not a substitute
                ! for a validation failure. Mutation guards must reject first.
                if(d%stop_status/=0) error stop 'mutation reached user ERROR STOP instead of a guard'
            end if
        end do
    end do
    ! Reuse the immutable IR after both successful and budget-failed roots.
    ! Each root must restore independent host activations and array bindings.
    call baseline()
    do which=1,3
        d=diagnostic_t()
        call execute_program(p,d)
        call expect(d%code==0,'host state or array binding leaked between successful root executions')
        call expect(p%symbols(scalar)%scope==host,'execution mutated scalar lexical scope')
        call expect(p%procedures(child)%parent_procedure==host,'execution mutated lexical parent')
    end do
    do which=1,3
        budget=int(8*which,int64)
        d=diagnostic_t()
        call execute_program(p,d,budget_remaining=budget)
        call expect(d%code==2.and.budget==0_int64,'nested calls must share and exhaust the work budget')
        d=diagnostic_t()
        call execute_program(p,d)
        call expect(d%code==0,'host activation or array binding leaked after budget failure')
    end do
    ! A caller-supplied stack is not authority to invent a live host. This
    ! zero-argument sibling has valid lexical metadata and argument count,
    ! but there is no live host activation in the fresh execution context.
    call baseline()
    d=diagnostic_t()
    call execute_program(p,d,procedure_index=sibling,argument_values=empty_arguments,call_stack=[host])
    call expect(d%code==2.and.d%stop_status==0,'forged direct call stack must not manufacture a live host')
    call expect(allocated(d%message),'forged direct frame rejection lacks a diagnostic')
    call expect(len_trim(d%message)>0,'forged direct frame rejection has an empty diagnostic')
    d=diagnostic_t()
    call execute_program(p,d)
    call expect(d%code==0,'forged direct frame call leaked live references into a later root')
    print '(a,i0,a)','PASS: ',checks,' internal host adapter/runtime/visibility/reset checks'
contains
    subroutine baseline()
        call parse_subset(source,p,d)
        if(d%code/=0) then
            if(allocated(d%message)) print *,d%message
            error stop 'internal procedure baseline parse failed'
        end if
        host=0;child=0;sibling=0;outsider=0;scalar=0;array=0;dummy=0;main_call=0
        main_scalar=0;child_read=0;child_write=0;second_call=0
        do j=1,p%np
            select case(trim(p%procedures(j)%name))
            case('host');host=j
            case('descend');child=j
            case('sibling');sibling=j
            case('outsider');outsider=j
            end select
        end do
        if(min(host,child,sibling,outsider)==0) error stop 'baseline procedure metadata missing'
        do j=1,p%ns
            if(p%symbols(j)%scope==0.and.p%symbols(j)%name=='total') main_scalar=j
            if(p%symbols(j)%scope/=host) cycle
            select case(trim(p%symbols(j)%name))
            case('state');scalar=j
            case('a');array=j
            case('n');dummy=j
            end select
        end do
        do j=1,p%ne
            if(p%expressions(j)%scope/=child.or.p%expressions(j)%kind/=ex_variable) cycle
            if(p%expressions(j)%symbol==scalar) child_read=j
        end do
        do j=1,p%nc
            if(p%code(j)%scope==child.and.p%code(j)%op==op_assign) then
                if(p%code(j)%symbol==scalar) child_write=j
            end if
            if(p%code(j)%scope/=0.or.p%code(j)%op/=op_call) cycle
            if(p%code(j)%symbol/=host) cycle
            if(main_call==0) then
                main_call=j
            else
                second_call=j
            end if
        end do
        if(min(scalar,array,dummy,main_call)==0) error stop 'baseline binding metadata missing'
        if(min(main_scalar,child_read,child_write,second_call)==0) error stop 'adversarial metadata missing'
    end subroutine
    subroutine expect(ok,what)
        logical,intent(in)::ok
        character(*),intent(in)::what
        checks=checks+1
        if(ok) return
        print *,what,d%code
        if(allocated(d%message)) print *,d%message
        error stop 1
    end subroutine
end program
