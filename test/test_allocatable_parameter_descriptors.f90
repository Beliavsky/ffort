! SPDX-License-Identifier: MIT
program test_allocatable_parameter_descriptors
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: execute_program
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='module m'//nl//'integer,parameter::a(-1:0)=[3,4]'//nl// &
        'integer,parameter::b(-2:-1,4:6)=reshape([1,2,3,4,5,6],[2,3])'//nl// &
        'integer,allocatable::live(:)'//nl//'contains'//nl// &
        'integer function f() result(n)'//nl// &
        'n=sum(a)+sum(b)+sum(b(-1,4:6:2))+lbound(a,1)+ubound(b,2)'//nl//'end function'//nl// &
        'subroutine nested()'//nl//'if(f()/=41) error stop 1'//nl// &
        'if(lbound(live,1)/=-3.or.sum(live)/=16) error stop 2'//nl//'end subroutine'//nl// &
        'end module'//nl//'program main'//nl//'use m'//nl// &
        'allocate(live(-3:-2))'//nl//'live=8'//nl//'call nested()'//nl//'end program'
    type(program_t)::p
    type(diagnostic_t)::d
    integer::i
    call parse_subset(source,p,d)
    if(d%code/=0) error stop 'parameter descriptors parse'
    call verify_frontend(source,p,d)
    if(d%code/=0) then
        print *,d%message
        error stop 'parameter descriptors frontend'
    end if
    do i=1,2
        call execute_program(p,d)
        if(d%code/=0) then
            print *,d%message
            error stop 'nested parameter bounds or live module allocation reset'
        end if
    end do
    p%symbols(1)%upper_bound=1
    call verify_frontend(source,p,d)
    if(d%code/=1) error stop 'parameter bound adapter mutation escaped'
    d=diagnostic_t()
    call execute_program(p,d)
    if(d%code/=2) error stop 'parameter bound runtime mutation escaped'
    print '(a)','PASS: nested module parameter descriptors and preserved shape validation'
end program
