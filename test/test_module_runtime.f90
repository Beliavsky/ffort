! SPDX-License-Identifier: MIT
program test_module_runtime
    use, intrinsic :: iso_fortran_env, only: int64
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_runtime, only: execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='module m'//nl//'implicit none'//nl//'contains'//nl// &
        'function twice(x) result(y)'//nl//'real, intent(in) :: x'//nl//'real :: y'//nl// &
        'y=2*x'//nl//'end function twice'//nl//'end module m'//nl// &
        'program main'//nl//'use m'//nl//'real :: value'//nl//'value=twice(2.3)'//nl//'end program main'
    integer::which,e,f,s
    do which=1,13
        call parse_subset(source,p,d)
        if(d%code/=0) then
            print *,d%message
            error stop 'module runtime fixture parse failed'
        end if
        e=p%code(p%entry_pc)%a; f=1; s=p%procedures(f)%args(1)
        select case(which)
        case(2)
            p%procedures(f)%args=[integer::]
        case(3)
            p%symbols(s)%typ=ty_integer
        case(4)
            p%code(p%procedures(f)%first)%symbol=s
        case(5)
            p%procedures(f)%result_symbol=s
        case(6)
            p%procedures(f)%last=p%procedures(f)%first-1
        case(7)
            p%code(p%procedures(f)%first)%scope=0
        case(8)
            p%expressions(e)%rank=1
        case(9)
            p%expressions(e)%typ=ty_integer
        case(10)
            deallocate(p%procedures)
        case(11)
            p%np=max_procedures+1
        case(12)
            p%procedures(f)%result_symbol=p%ns+1
        case(13)
            p%procedures(f)%args(1)=p%ns+1
        end select
        call execute_program(p,d)
        if((d%code==0).neqv.(which==1)) then
            print *,which
            if(allocated(d%message)) print *,d%message
            error stop 'module runtime invariant regression'
        end if
    end do
    call parse_subset(source,p,d)
    call execute_program(p,d,max_steps=3_int64)
    if(d%code/=2) error stop 'module shared budget regression'
    print '(a)','PASS: module runtime baseline, 12 invariant rejections and shared budget'
end program
