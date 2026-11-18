! SPDX-License-Identifier: MIT
! Deliberate IR mutations verify that named constants are not trusted caches.
program test_program_forms_frontend
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: evaluate_constant
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    type(value_t)::v
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        'integer, parameter :: n=2**5, m=n+1'//nl// &
        'real, parameter :: r=real(m)/2.0'//nl//'logical, parameter :: yes=m>n'//nl// &
        'integer :: a(n:m), x=m'//nl//'a(n)=x'//nl//'print *,a(n),r,yes'//nl//'end program p'
    integer::which
    do which=1,10
        call parse_subset(source,p,d)
        if(d%code/=0) then
            print *,d%message
            error stop 'parameter adapter baseline parse failed'
        end if
        select case(which)
        case(2)
            p%symbols(1)%is_parameter=.false.
        case(3)
            p%symbols(1)%parameter_ready=.false.
        case(4)
            p%symbols(1)%constant_value%i=31
        case(5)
            p%symbols(1)%constant_value%tag=ty_real
        case(6)
            p%symbols(1)%initializer_expr=0
        case(7)
            p%symbols(3)%constant_value%r=0.0
        case(8)
            p%symbols(4)%constant_value%l=.false.
        case(9)
            p%symbols(6)%is_parameter=.true.
        case(10)
            p%expressions(p%symbols(2)%initializer_expr)%op='-'
        end select
        call verify_frontend(source,p,d)
        call outcome(which==1,'parameter adapter')
    end do
    do which=1,3
        call parse_subset('print*,2**5'//nl//'end',p,d)
        if(d%code/=0) error stop 'implicit main baseline parse failed'
        if(which==2) p%name='different'
        if(which==3) p%end_line=1
        call verify_frontend('print*,2**5'//nl//'end',p,d)
        call outcome(which==1,'implicit main adapter')
    end do
    ! A mutable variable, even with a constant initializer, is not a constant.
    call parse_subset('integer :: x=1'//nl//'print *,x'//nl//'end',p,d)
    if(d%code/=0) error stop 'constant evaluator fixture parse failed'
    call evaluate_constant(p,p%code(p%nc)%items(1),v,d)
    call outcome(.false.,'constant evaluator variable rejection')
    print '(a)','PASS: 2 program-form adapter baselines, 11 disagreements, 1 constant-evaluator rejection'
contains
    subroutine outcome(want_success,label)
        logical,intent(in)::want_success
        character(*),intent(in)::label
        if((d%code==0).eqv.want_success) return
        print *,label,which
        if(allocated(d%message)) print *,d%message
        error stop 'program-form adapter regression'
    end subroutine
end program
