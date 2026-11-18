! SPDX-License-Identifier: MIT
! Synthetic composition only. Original source bodies live in the source suite.
program test_release034_composition
    use, intrinsic :: iso_fortran_env, only: int64, output_unit, error_unit
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: execute_program
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='module m'//nl//'implicit none'//nl//'contains'//nl// &
        'pure integer function span(n) result(v)'//nl//'integer,intent(in)::n'//nl// &
        'v=n'//nl//'end function'//nl//'subroutine report(char)'//nl// &
        'integer,allocatable,intent(inout)::char(:)'//nl// &
        'integer::work(span(size(char))),entry'//nl//'character(len=size(char))::label'//nl// &
        'character(8)::record'//nl//'integer,save::calls=0'//nl// &
        'entry=size(char)'//nl//'calls=calls+1'//nl//'work=calls'//nl// &
        "label=' x'"//nl//"write(record,'(2(i2))')work"//nl// &
        "if(calls==1.and.record/=' 1 1    ') error stop 1"//nl// &
        "if(calls==2.and.record/=' 2      ') error stop 2"//nl// &
        "if(calls==3.and.record/='        ') error stop 3"//nl// &
        'deallocate(char)'//nl//'allocate(char(1))'//nl//'char=99'//nl// &
        'if(size(work)/=entry.or.len(label)/=entry) error stop 4'//nl// &
        'write(*,''("visit",2(1x,i0))'')calls,size(work)'//nl// &
        'end subroutine'//nl//'end module'//nl//'program main'//nl//'use m'//nl// &
        'integer,allocatable::data(:)'//nl//'allocate(data(-1:0))'//nl// &
        'call report(data)'//nl//'call report(data)'//nl//'deallocate(data)'//nl// &
        'allocate(data(0))'//nl//'call report(data)'//nl//'end program'
    character(*),parameter::shadow_source='module m'//nl//'implicit none'//nl// &
        'interface char'//nl//'module procedure convert'//nl//'end interface'//nl//'contains'//nl// &
        'pure character(1) function convert(n) result(v)'//nl//'integer,intent(in)::n'//nl// &
        'v="Z"'//nl//'end function'//nl//'subroutine report(values)'//nl// &
        'integer,allocatable,intent(in)::values(:)'//nl//'integer::work(size(values))'//nl// &
        'work=1'//nl//'write(*,''("[",2(a),"]")'')char(65)," "'//nl// &
        'end subroutine'//nl//'end module'//nl//'program main'//nl//'use m'//nl// &
        'integer,allocatable::a(:)'//nl//'allocate(a(0))'//nl//'call report(a)'//nl//'end program'
    type(program_t)::p,q
    type(diagnostic_t)::d
    integer::checks,which,stage,j,dummy,work,saved,output,inner,call_expr,read_status
    integer(int64)::budget,used
    character(64)::line
    checks=0
    close(output_unit)
    open(unit=output_unit,status='scratch',action='readwrite',form='formatted')
    call parse_subset(source,p,d)
    call expect(d%code==0,'parse composition')
    call verify_frontend(source,p,d)
    call expect(d%code==0,'verify composition')
    dummy=0;work=0;saved=0;output=0;inner=0
    do j=1,p%ns
        select case(p%symbols(j)%name)
        case('char');dummy=j
        case('work');work=j
        case('calls');saved=j
        end select
    end do
    do j=1,p%nc
        if(p%code(j)%op==op_print)output=j
        if(p%code(j)%op==op_write_internal)inner=j
    end do
    call expect(min(dummy,work,saved,output,inner)>0,'find composition identities')
    do j=1,3
        call clear_output()
        d=diagnostic_t();call execute_program(p,d)
        call expect(d%code==0,'repeat root execution')
        call expect_output()
        call expect(p%symbols(saved)%constant_value%i==0_int64,'saved initializer immutable')
    end do
    do which=1,8
        do stage=1,2
            q=p
            select case(which)
            case(1);q%symbols(dummy)%dummy_intent=2
            case(2);q%symbols(dummy)%is_optional=.true.
            case(3);q%symbols(work)%is_saved=.true.;q%symbols(work)%initializer_expr=p%symbols(saved)%initializer_expr
            case(4);q%code(output)%symbol=dummy
            case(5);q%code(output)%generic_id=1
            case(6);q%code(output)%items=[q%ne+1]
            case(7);q%code(output)%format='(0(i0))'
            case(8);q%code(inner)%format='(0(i0))'
            end select
            d=diagnostic_t();call clear_output()
            if(stage==1)then
                call verify_frontend(source,q,d)
                call expect(d%code==1,'adapter rejects forged composition')
            else
                call execute_program(q,d)
                call expect(d%code==2,'runtime rejects forged composition')
                call expect(allocated(d%message),'runtime has diagnostic')
            end if
            rewind(output_unit)
            read(output_unit,'(a)',iostat=read_status)line
            call expect(read_status<0,'forged composition emits nothing')
        end do
    end do
    call clear_output();budget=100000_int64;d=diagnostic_t()
    call execute_program(p,d,budget_remaining=budget)
    call expect(d%code==0,'measure root budget')
    used=100000_int64-budget
    call expect(used>1,'nonempty budget')
    call clear_output();budget=used-1;d=diagnostic_t()
    call execute_program(p,d,budget_remaining=budget)
    call expect(d%code==2.and.budget==0,'late shared budget failure')
    call expect(index(d%message,'execution step limit exceeded')>0,'budget-specific diagnostic')
    call clear_output();d=diagnostic_t();call execute_program(p,d)
    call expect(d%code==0,'root reset after late failure')
    call expect_output()
    d=diagnostic_t();call parse_subset(shadow_source,q,d)
    call expect(d%code==0,'parse generic CHAR output composition')
    call verify_frontend(shadow_source,q,d)
    call expect(d%code==0,'verify generic CHAR output composition')
    call clear_output();call execute_program(q,d)
    call expect(d%code==0,'run generic CHAR output composition')
    rewind(output_unit);read(output_unit,'(a)',iostat=read_status)line
    call expect(read_status==0.and.trim(line)=='[Z ]','generic CHAR remains user call')
    call_expr=0
    do j=1,q%ne
        if(q%expressions(j)%kind==ex_user_call)call_expr=j
    end do
    call expect(call_expr>0,'find generic CHAR expression')
    q%expressions(call_expr)%kind=ex_call;q%expressions(call_expr)%op='char'
    q%expressions(call_expr)%symbol=0;q%expressions(call_expr)%generic_id=0
    d=diagnostic_t();call verify_frontend(shadow_source,q,d)
    call expect(d%code==1,'adapter rejects same-type generic CHAR as intrinsic')
    close(output_unit)
    write(error_unit,'(a,i0,a)')'PASS: release 0.34 composition: ',checks,' checks'
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
    subroutine expect_output()
        rewind(output_unit)
        read(output_unit,'(a)',iostat=read_status)line
        call expect(read_status==0.and.trim(line)=='visit 1 2','first grouped record')
        read(output_unit,'(a)',iostat=read_status)line
        call expect(read_status==0.and.trim(line)=='visit 2 1','second grouped record')
        read(output_unit,'(a)',iostat=read_status)line
        call expect(read_status==0.and.trim(line)=='visit 3 0','empty frozen frame record')
        read(output_unit,'(a)',iostat=read_status)line
        call expect(read_status<0,'no extra output')
    end subroutine
end program
