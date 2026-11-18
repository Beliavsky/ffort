! SPDX-License-Identifier: MIT
program test_random_stream_runtime
    use, intrinsic :: iso_fortran_env, only: int64
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_runtime, only: execute_program
    implicit none
    character(*),parameter::nl=new_line('a')
    type(program_t)::p
    type(diagnostic_t)::d
    integer(int64)::state,wanted
    integer::j,k
    character(*),parameter::source= &
        'program p'//nl// &
        'real(8) :: a(2,3), x(3)'//nl// &
        'real :: b(3)'//nl// &
        'integer :: n, undefined'//nl// &
        'a=-1.0d0'//nl// &
        'call fill(a(2,3:1:-1))'//nl// &
        'call fill(x)'//nl// &
        "if (sum(a(1,:))/=-3.0d0) error stop 'untouched section'"//nl// &
        "if (minval(a(2,:))<0.0d0) error stop 'negative harvest'"//nl// &
        "if (maxval(a(2,:))>=1.0d0) error stop 'upper range'"//nl// &
        'call random_number(b)'//nl// &
        "if (minval(b)<0.0.or.maxval(b)>=1.0) error stop 'real32 range'"//nl// &
        'n=kind(a(undefined,1))'//nl// &
        "if (n/=8) error stop 'undefined subscript evaluated'"//nl// &
        'n=kind(1/0)'//nl// &
        "if (n/=4) error stop 'arithmetic argument evaluated'"//nl// &
        'n=kind(noisy(1.0))'//nl// &
        "if (n/=4) error stop 'kind value'"//nl// &
        'contains'//nl// &
        'subroutine fill(v)'//nl// &
        'real(8), intent(out) :: v(:)'//nl// &
        'call deeper(v)'//nl// &
        'end subroutine fill'//nl// &
        'subroutine deeper(v)'//nl// &
        'real(8), intent(out) :: v(:)'//nl// &
        'call random_number(v)'//nl// &
        'end subroutine deeper'//nl// &
        'impure elemental real function noisy(v) result(r)'//nl// &
        'real, intent(in) :: v'//nl// &
        'call random_number(r)'//nl// &
        "error stop 'KIND evaluated its argument'"//nl// &
        'end function noisy'//nl// &
        'end program p'
    call parse_subset(source,p,d)
    if(d%code/=0) then
        print *,d%message
        error stop 'stream test parse'
    end if
    state=104729_int64;wanted=state
    do j=1,9
        wanted=modulo(wanted*16807_int64,2147483647_int64)
    end do
    call execute_program(p,d,random_state=state)
    if(d%code/=0) then
        print *,d%message
        error stop 'stream execution'
    end if
    if(state/=wanted) error stop 'nested calls did not share generator state'
    ! A forged SIMPLE procedure without its implied PURE bit remains forbidden.
    do k=1,p%np
        if(p%procedures(k)%name/='deeper') cycle
        p%procedures(k)%is_simple=.true.;p%procedures(k)%is_pure=.false.
    end do
    d=diagnostic_t();state=104729_int64
    call execute_program(p,d,random_state=state)
    if(d%code/=2) error stop 'SIMPLE random_number was accepted'
    call parse_subset('program p'//nl//'real :: x(2)'//nl// &
        'call random_number(x(idx(1):))'//nl//'contains'//nl// &
        'impure elemental integer function idx(v) result(r)'//nl// &
        'integer, intent(in) :: v'//nl//'real :: a(2)'//nl// &
        'call random_number(a(1:))'//nl//'r=0'//nl//'end function'//nl//'end program',p,d)
    if(d%code/=0) error stop 'nested descriptor parse failed'
    state=104729_int64
    call execute_program(p,d,random_state=state)
    if(d%code/=2.or.state/=104729_int64) error stop 'nested descriptor failure did not restore RNG'
    print '(a)','PASS: nested RNG stream, reversed rank-two section, REAL32 range and unevaluated KIND call'
end program
