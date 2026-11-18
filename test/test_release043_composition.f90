! SPDX-License-Identifier: MIT
! Independently authored allocation/READ composition and source-binding mutations.
program test_release043_composition
    use, intrinsic :: iso_fortran_env, only: error_unit
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: execute_program
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        'character(:),allocatable::s,t'//nl//'integer::n,ios'//nl// &
        's="41"'//nl//'t="41"'//nl//'read(s,*,iostat=ios) n'//nl// &
        'if(ios/=0.or.n/=41) error stop 1'//nl//'s=s//"2"'//nl// &
        'read(s,*,iostat=ios) n'//nl//'if(ios/=0.or.n/=412) error stop 2'//nl// &
        'end program'
    type(program_t)::p,q
    type(diagnostic_t)::d
    integer::j,pc,alternate,checks
    checks=0
    call parse_subset(source,p,d)
    call expect(d%code==0,'parse allocatable READ composition')
    call verify_frontend(source,p,d)
    call expect(d%code==0,'verify allocatable READ composition')
    pc=0;alternate=0
    do j=1,p%nc
        if(p%code(j)%op==op_read_internal.and.pc==0) pc=j
    end do
    do j=1,p%ns
        if(p%symbols(j)%name=='t') alternate=j
    end do
    call expect(pc>0.and.alternate>0,'locate independent file and instruction')
    do j=1,3
        d=diagnostic_t();call execute_program(p,d)
        call expect(d%code==0,'fresh allocations across repeated immutable execution')
    end do
    q=p;q%expressions(q%code(pc)%a)%symbol=alternate
    d=diagnostic_t();call verify_frontend(source,q,d)
    call expect(d%code==1,'reject same-valued different allocatable source identity')
    q=p;q%code(pc)%items=[q%code(pc)%items(1),q%code(pc)%items(1)]
    call expect(.not.valid_internal_read(q,q%code(pc)),'reject duplicate target public IR')
    d=diagnostic_t();call verify_frontend(source,q,d)
    call expect(d%code==1,'reject duplicate target adapter')
    d=diagnostic_t();call execute_program(q,d)
    call expect(d%code==2,'reject duplicate target direct runtime')
    d=diagnostic_t();call execute_program(p,d)
    call expect(d%code==0,'malformed copy did not damage immutable original ownership')
    write(error_unit,'(a,i0,a)') 'release043 composition native: ',checks,' checks passed'
contains
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok)return
        write(error_unit,'(a)') 'FAIL: '//label
        if(allocated(d%message))write(error_unit,'(a)') d%message
        error stop 1
    end subroutine
end program
