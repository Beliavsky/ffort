! SPDX-License-Identifier: MIT
! Independent composition: live host state + SAVE + recursion + grouped output.
program test_release035_composition
    use, intrinsic::iso_fortran_env,only:int64,output_unit,error_unit
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source= &
        'module live_composition'//nl // &
        'implicit none'//nl // &
        'contains'//nl // &
        'subroutine host(n,a)'//nl // &
        'integer,intent(in)::n'//nl // &
        'integer,intent(inout)::a(:)'//nl // &
        'integer,save::calls=0'//nl // &
        'integer::state'//nl // &
        'character(5)::char'//nl // &
        'state=n'//nl // &
        'char=''a b  '''//nl // &
        'calls=calls+1'//nl // &
        'call descend(n)'//nl // &
        'write(*,''("frame",2(1x,i0)," [",a,"]")'')calls,state,char'//nl // &
        'write(*,''("array",2(1x,i0))'')a'//nl // &
        'contains'//nl // &
        'recursive subroutine descend(k)'//nl // &
        'integer,intent(in)::k'//nl // &
        'integer::local'//nl // &
        'local=k'//nl // &
        'if(k>0)call descend(k-1)'//nl // &
        'state=state+local'//nl // &
        'a=a+local'//nl // &
        'call sibling()'//nl // &
        'end subroutine'//nl // &
        'subroutine sibling()'//nl // &
        'char=''x y  '''//nl // &
        'state=state+1'//nl // &
        'end subroutine'//nl // &
        'end subroutine'//nl // &
        'end module'//nl // &
        'program main'//nl // &
        'use live_composition'//nl // &
        'implicit none'//nl // &
        'integer::a(2)'//nl // &
        'a=[1,2]'//nl // &
        'call host(2,a)'//nl // &
        'call host(1,a)'//nl // &
        'end program'//nl

    type(program_t)::p,q
    type(diagnostic_t)::d
    type(value_t)::no_arguments(0)
    integer::checks,j,which,stage,host,child,sibling,scalar,array,saved,output,status
    integer(int64)::budget
    character(80)::line
    checks=0;which=0;stage=0
    close(output_unit)
    open(unit=output_unit,status='scratch',action='readwrite',form='formatted')
    call parse_subset(source,p,d)
    call expect(d%code==0,'parse composition')
    call verify_frontend(source,p,d)
    call expect(d%code==0,'verify composition')
    host=0;child=0;sibling=0;scalar=0;array=0;saved=0;output=0
    do j=1,p%np
        select case(p%procedures(j)%name)
        case('host');host=j
        case('descend');child=j
        case('sibling');sibling=j
        end select
    end do
    do j=1,p%ns
        if(p%symbols(j)%scope/=host)cycle
        select case(p%symbols(j)%name)
        case('state');scalar=j
        case('a');array=j
        case('calls');saved=j
        end select
    end do
    do j=1,p%nc
        if(p%code(j)%scope==host.and.p%code(j)%op==op_print.and.output==0)output=j
    end do
    call expect(min(host,child,sibling,scalar,array,saved,output)>0,'find scoped identities')
    do which=1,3
        call clear_output();d=diagnostic_t();call execute_program(p,d)
        call expect(d%code==0,'repeat root succeeds')
        call expect_records()
        call expect(p%symbols(saved)%constant_value%i==0_int64,'SAVE initializer remains immutable')
        call expect(p%procedures(child)%parent_procedure==host,'lexical parent remains immutable')
    end do
    do which=1,12
        do stage=1,2
            q=p
            select case(which)
            case(1);q%procedures(child)%parent_procedure=0
            case(2);q%procedures(child)%parent_procedure=sibling
            case(3);q%procedures(sibling)%is_public=.true.
            case(4);q%procedures(child)%is_pure=.true.
            case(5);q%symbols(array)%is_allocatable=.true.
            case(6);q%symbols(array)%dummy_intent=1
            case(7);q%symbols(scalar)%is_pointer=.true.
            case(8);q%symbols(scalar)%scope=0
            case(9);q%code(output)%format='(0(i0))'
            case(10);q%code(output)%items=[q%ne+1]
            case(11);q%code(output)%generic_id=1
            case(12);q%procedures(child)%is_recursive=.false.
            end select
            call clear_output();d=diagnostic_t()
            if(stage==1)then
                call verify_frontend(source,q,d)
            else
                call execute_program(q,d,max_steps=5000_int64)
            end if
            call expect(d%code==stage,'forged metadata rejected independently')
            call expect(d%stop_status==0,'rejection is a guard, not user STOP')
            call expect(allocated(d%message),'guard diagnostic allocated')
            call expect(len_trim(d%message)>0,'guard diagnostic nonempty')
            rewind(output_unit);read(output_unit,'(a)',iostat=status)line
            call expect(status<0,'forged metadata emits no partial or prior records')
        end do
    end do
    do which=1,3
        call clear_output();budget=int(10*which,int64);d=diagnostic_t()
        call execute_program(p,d,budget_remaining=budget)
        call expect(d%code==2.and.budget==0_int64,'nested work uses shared budget')
        call expect(index(d%message,'execution step limit exceeded')>0,'budget-specific failure')
        call clear_output();d=diagnostic_t();call execute_program(p,d)
        call expect(d%code==0,'frame and SAVE reset after checked failure')
        call expect_records()
    end do
    call clear_output();d=diagnostic_t()
    call execute_program(p,d,procedure_index=sibling,argument_values=no_arguments,call_stack=[host])
    call expect(d%code==2.and.d%stop_status==0,'forged stack has no live defining host')
    call expect(allocated(d%message),'missing live host has diagnostic')
    rewind(output_unit);read(output_unit,'(a)',iostat=status)line
    call expect(status<0,'orphan child emits nothing')
    call clear_output();d=diagnostic_t();call execute_program(p,d)
    call expect(d%code==0,'orphan rejection does not poison next root')
    call expect_records()
    close(output_unit)
    write(error_unit,'(a,i0,a)')'PASS: release 0.35 composition: ',checks,' checks'
contains
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok)return
        write(error_unit,*)label,' mutation=',which,' stage=',stage,' code=',d%code
        if(allocated(d%message))write(error_unit,*)d%message
        error stop 1
    end subroutine
    subroutine clear_output()
        rewind(output_unit)
        endfile(output_unit)
        rewind(output_unit)
    end subroutine
    subroutine expect_records()
        rewind(output_unit)
        call record('frame 1 8 [x y  ]')
        call record('array 4 5')
        call record('frame 2 4 [x y  ]')
        call record('array 5 6')
        read(output_unit,'(a)',iostat=status)line
        call expect(status<0,'no additional records')
    end subroutine
    subroutine record(want)
        character(*),intent(in)::want
        read(output_unit,'(a)',iostat=status)line
        call expect(status==0.and.trim(line)==want,'exact grouped record: '//want)
    end subroutine
end program
