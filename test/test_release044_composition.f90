! SPDX-License-Identifier: MIT
! Independent merged-feature mutations. No shared library is built by this test.
program test_release044_composition
    use, intrinsic :: iso_fortran_env, only: error_unit,int64
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: execute_program
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        'character(24)::fmt,other'//nl//'character(16)::s'//nl//'character(7)::label'//nl// &
        'integer::i,k'//nl//'real(8)::angles(2)'//nl// &
        'fmt="(*(f4.1,1x))"'//nl//'other="(*(f4.1,1x))"'//nl//'angles=[0d0,90d0]'//nl// &
        'write(s,fmt)(sind(angles(i)),i=1,2)'//nl// &
        'if(trim(s)/=" 0.0  1.0") error stop 1'//nl// &
        'write(s,"(*(i0,1x))")(label%len+kind(label%len),i=1,2)'//nl// &
        'if(trim(s)/="11 11") error stop 2'//nl//'end program'
    type(program_t)::p,q
    type(diagnostic_t)::d
    integer::j,pc,root,fexpr,degree,lenexpr,other,alternate,checks,mutation
    checks=0;pc=0;root=0;fexpr=0;degree=0;lenexpr=0;other=0;alternate=0;mutation=0
    call parse_subset(source,p,d)
    call expect(d%code==0,'parse combined dynamic format / loop / degree / LEN source')
    call verify_frontend(source,p,d)
    call expect(d%code==0,'verify original combined source')
    do j=1,p%nc
        if(p%code(j)%op==op_write_internal.and.pc==0)pc=j
    end do
    do j=1,p%ne
        if(p%expressions(j)%op=='sind')degree=j
        if(p%expressions(j)%op=='len'.and.lenexpr==0)lenexpr=j
    end do
    do j=1,p%ns
        if(p%symbols(j)%name=='other')other=j
        if(p%symbols(j)%name=='k')alternate=j
    end do
    call expect(pc>0.and.degree>0.and.lenexpr>0.and.other>0.and.alternate>0,'locate combined identities')
    root=p%code(pc)%items(1);fexpr=p%code(pc)%format_expr
    call expect(fexpr>0.and.valid_output_do(p,root),'dynamic format and implied-DO public gate')
    do j=1,3
        d=diagnostic_t();call execute_program(p,d)
        call expect(d%code==0,'repeat fresh combined execution')
    end do
    do mutation=1,7
        q=p
        select case(mutation)
        case(1);q%code(pc)%format_expr=root
        case(2);q%code(pc)%advance_mode=1
        case(3);q%expressions(root)%args(1)=fexpr
        case(4);q%expressions(degree)%rank=1
        case(5);q%expressions(degree)%args(1)=root
        case(6);q%expressions(lenexpr)%real_kind=8
        case(7);q%expressions(root)%args(1)=root
        end select
        d=diagnostic_t();call verify_frontend(source,q,d)
        call expect(d%code==1,'adapter rejects merged malformed metadata')
        d=diagnostic_t();call execute_program(q,d)
        call expect(d%code==2,'runtime rejects merged malformed metadata')
        call expect(allocated(d%message),'runtime rejection has diagnostic')
    end do
    q=p;q%expressions(fexpr)%symbol=other
    d=diagnostic_t();call verify_frontend(source,q,d)
    call expect(d%code==1,'same-valued alternate format fails exact source identity')
    q=p;q%expressions(root)%symbol=alternate
    call expect(valid_output_do(q,root),'alternate counter remains structurally admissible')
    d=diagnostic_t();call verify_frontend(source,q,d)
    call expect(d%code==1,'alternate counter fails exact source identity')
    d=diagnostic_t();call execute_program(p,d,max_steps=1_int64)
    call expect(d%code==2,'combined execution respects API step budget')
    call expect(d%message=='execution step limit exceeded','CLI hint does not leak into runtime API')
    d=diagnostic_t();call execute_program(p,d)
    call expect(d%code==0,'mutated copies and failed budget do not damage immutable source')
    write(error_unit,'(a,i0,a)')'release044 composition native: ',checks,' checks passed'
contains
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok)return
        write(error_unit,'(a,i0,2a)')'FAIL mutation ',mutation,': ',label
        if(allocated(d%message))write(error_unit,'(a)')d%message
        error stop 1
    end subroutine
end program
