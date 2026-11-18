! SPDX-License-Identifier: MIT
! TARGET metadata is checked independently; it does not implement pointer aliases.
program test_target_attributes
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: execute_program
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='module m'//nl// &
        'integer,target::a(1,1,2)'//nl//'contains'//nl// &
        'subroutine setup()'//nl//'integer,target::local'//nl// &
        'local=7'//nl//'a=local'//nl//'end subroutine'//nl//'end module'//nl// &
        'program main'//nl//'use m'//nl//'integer,parameter::k=2'//nl// &
        'real(kind=8),target::r'//nl//'logical,target,allocatable::b(:,:,:)'//nl// &
        'character(len=2),target::c'//nl//'integer::plain'//nl// &
        'r=2.5_8'//nl//'c="xy"'//nl//'plain=k'//nl// &
        'allocate(b(1,1,2))'//nl//'b=.true.'//nl//'call setup()'//nl// &
        'call inspect()'//nl//'call inspect(a)'//nl// &
        'if(a(1,1,2)/=7) error stop 1'//nl// &
        'if(.not.b(1,1,2)) error stop 2'//nl//'deallocate(b)'//nl// &
        'contains'//nl//'subroutine inspect(x)'//nl// &
        'integer,target,optional,intent(in)::x(:,:,:)'//nl// &
        'if(present(x)) then'//nl//'if(x(1,1,1)/=7) error stop 3'//nl// &
        'end if'//nl//'end subroutine'//nl//'end program'
    type(program_t)::p
    type(diagnostic_t)::d
    integer::i,j,n,parameter_symbol,ordinary_symbol
    call fresh()
    call verify_frontend(source,p,d)
    call require_ok('frontend')
    n=count(p%symbols(:p%ns)%is_target)
    if(n/=6) error stop 'TARGET metadata not preserved on every declaration'
    do i=1,3
        d=diagnostic_t()
        call execute_program(p,d)
        call require_ok('repeated execution')
    end do
    ! Neither the source's TARGET attribute nor its absence may be forged in IR.
    n=p%ns
    do i=1,n
        call fresh()
        p%symbols(i)%is_target=.not.p%symbols(i)%is_target
        call verify_frontend(source,p,d)
        if(d%code/=1) then
            print *,i,trim(p%symbols(i)%name),d%code
            error stop 'forged TARGET metadata escaped adapter'
        end if
    end do
    call fresh()
    parameter_symbol=0;ordinary_symbol=0
    do j=1,p%ns
        if(p%symbols(j)%name=='k') parameter_symbol=j
        if(p%symbols(j)%name=='plain') ordinary_symbol=j
    end do
    if(parameter_symbol==0.or.ordinary_symbol==0) error stop 'missing fixture symbols'
    ! Runtime independently rejects impossible PARAMETER+TARGET combinations.
    p%symbols(parameter_symbol)%is_target=.true.
    call execute_program(p,d)
    if(d%code/=2) error stop 'PARAMETER TARGET escaped runtime'
    ! Legal TARGET metadata alone must not impose a pointer lifetime requirement.
    call fresh()
    p%symbols(ordinary_symbol)%is_target=.true.
    call execute_program(p,d)
    call require_ok('legal ordinary TARGET runtime metadata')
    print '(a,i0,a)','PASS: TARGET reset, ',n,' adapter mutations and PARAMETER runtime rejection'
contains
    subroutine fresh()
        d=diagnostic_t()
        call parse_subset(source,p,d)
        call require_ok('parse')
    end subroutine
    subroutine require_ok(label)
        character(*),intent(in)::label
        if(d%code==0) return
        print *,label,': ',d%message
        error stop 'unexpected TARGET diagnostic'
    end subroutine
end program
