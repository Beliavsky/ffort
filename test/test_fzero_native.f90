! SPDX-License-Identifier: MIT
! Prepared for central execution; not compiled or run in checkpoint 2.
program test_fzero_native
    use, intrinsic :: iso_fortran_env, only: real32, real64
    use, intrinsic :: ieee_arithmetic, only: ieee_value, ieee_quiet_nan, ieee_positive_inf
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: execute_program
    implicit none
    character(*), parameter :: nl = new_line('a')
    character(*), parameter :: source = 'implicit none'//nl// &
        'real, parameter :: x=1.25'//nl//'character(len=1340)::s'//nl// &
        'write(s,"(f0.1024)") x'//nl//'end'//nl
    type(program_t) :: p, q
    type(diagnostic_t) :: d
    integer :: i, sym, k, checks
    real(real64) :: invalid(4)
    checks=0
    call parse_subset(source,p,d)
    call require(d%code==0,'parse F0 parameter fixture')
    d=diagnostic_t()
    call verify_frontend(source,p,d)
    call require(d%code==0,'verify F0 parameter fixture')
    sym=0
    do i=1,p%ns
        if(p%symbols(i)%name=='x') sym=i
    end do
    call require(sym>0,'find REAL4 parameter cache')
    call require(p%symbols(sym)%parameter_ready,'parameter cache ready')
    d=diagnostic_t()
    call execute_program(p,d)
    call require(d%code==0,'baseline precision boundary')
    invalid=[huge(0.0_real64),-huge(0.0_real64), &
        2.0_real64*real(huge(0.0_real32),real64),-2.0_real64*real(huge(0.0_real32),real64)]
    do k=1,size(invalid)
        q=p
        q%symbols(sym)%constant_value%r=invalid(k)
        do i=1,2
            d=diagnostic_t()
            call execute_program(q,d)
            call require(d%code==2,'reject forged REAL4 cache before narrowing')
            call require(allocated(d%message),'finite range diagnostic allocated')
            call require(index(d%message,'F0 REAL kind 4 value exceeds its finite range')>0, &
                'F0-specific range diagnostic')
        end do
        d=diagnostic_t()
        call execute_program(p,d)
        call require(d%code==0,'fresh valid execution after failure')
    end do
    do k=1,4
        q=p
        select case(k)
        case(1);q%symbols(sym)%constant_value%r=real(huge(0.0_real32),real64)
        case(2);q%symbols(sym)%constant_value%r=-real(huge(0.0_real32),real64)
        case(3);q%symbols(sym)%constant_value%r=0.0_real64
        case(4);q%symbols(sym)%constant_value%r=-0.0_real64
        end select
        d=diagnostic_t()
        call execute_program(q,d)
        call require(d%code==0,'finite REAL4 boundary allowed')
    end do
    do k=1,2
        q=p
        if(k==1)then
            q%symbols(sym)%constant_value%r=ieee_value(0.0_real64,ieee_quiet_nan)
        else
            q%symbols(sym)%constant_value%r=ieee_value(0.0_real64,ieee_positive_inf)
        end if
        d=diagnostic_t()
        call execute_program(q,d)
        call require(d%code==2,'reject nonfinite parameter cache')
        call require(allocated(d%message),'nonfinite diagnostic allocated')
        call require(index(d%message,'non-finite PARAMETER value')>0,'existing nonfinite diagnostic')
    end do
    print '(a,i0)', 'PASS F0 native assertions: ',checks
contains
    subroutine require(ok,message)
        logical,intent(in)::ok
        character(*),intent(in)::message
        checks=checks+1
        if(.not.ok)then
            print '(a)', 'FAIL '//message
            if(allocated(d%message))print '(a)',d%message
            error stop 1
        end if
    end subroutine
end program
