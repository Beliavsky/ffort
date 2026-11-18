! SPDX-License-Identifier: MIT
program test_mutable_modules
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: execute_program
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='module state'//nl// &
        'integer::counter=2,vec(2)=[3,4]'//nl//'contains'//nl// &
        'subroutine bump()'//nl//'counter=counter+1'//nl//'vec(2)=counter'//nl//'end subroutine'//nl// &
        'pure function readit() result(r)'//nl//'integer::r'//nl//'r=counter'//nl//'end function'//nl// &
        'end module'//nl//'program main'//nl//'use state'//nl// &
        'if(counter/=2) error stop 1'//nl//'call bump()'//nl//'call bump()'//nl// &
        'if(counter/=4.or.vec(1)/=3.or.vec(2)/=4.or.readit()/=4) error stop 1'//nl//'end program'
    type(program_t)::p
    type(diagnostic_t)::d
    integer::k,s,a
    call parse_subset(source,p,d)
    if(d%code/=0) then
        print *,d%message
        error stop 'mutable module parse'
    end if
    call verify_frontend(source,p,d)
    if(d%code/=0) then
        print *,d%message
        error stop 'mutable module adapter'
    end if
    do k=1,2
        d=diagnostic_t()
        call execute_program(p,d)
        if(d%code/=0) then
            print *,d%message
            error stop 'module lifetime/reset regression'
        end if
    end do
    do k=1,5
        call parse_subset(source,p,d)
        s=1;a=2
        select case(k)
        case(1)
            p%symbols(s)%parameter_ready=.false.
        case(2)
            p%symbols(a)%constant_values=p%symbols(a)%constant_values(:1)
        case(3)
            p%procedures(1)%is_pure=.true.
        case(4)
            p%procedures(2)%is_simple=.true.
        case(5)
            p%symbols(s)%is_public=.false.
        end select
        call verify_frontend(source,p,d)
        if(d%code/=1) error stop 'module adapter mutation escaped'
        d=diagnostic_t()
        call execute_program(p,d)
        if(d%code/=2) then
            print *,k,d%code
            error stop 'module runtime mutation escaped'
        end if
    end do
    print '(a)','PASS: mutable module lifetime/reset and 10 adapter/runtime mutation rejections'
end program
