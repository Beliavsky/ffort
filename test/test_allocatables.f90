! SPDX-License-Identifier: MIT
program test_allocatables
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: execute_program
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='module m'//nl//'integer,allocatable::v(:)'//nl//'contains'//nl// &
        'subroutine setup()'//nl//'allocate(v(-1:1))'//nl//'v=7'//nl//'end subroutine'//nl// &
        'subroutine clean()'//nl//'deallocate(v)'//nl//'end subroutine'//nl//'end module'//nl// &
        'program main'//nl//'use m'//nl//'integer::s'//nl// &
        'if(allocated(v)) error stop 1'//nl//'call setup()'//nl// &
        'if(lbound(v,1)/=-1.or.sum(v)/=21) error stop 2'//nl// &
        'allocate(v(3),stat=s)'//nl//'if(s==0) error stop 3'//nl// &
        'call clean()'//nl//'if(allocated(v)) error stop 4'//nl//'end program'
    type(program_t)::p
    type(diagnostic_t)::d
    integer::i,j,a,q,stat
    call fresh()
    call verify_frontend(source,p,d)
    if(d%code/=0) then
        print *,d%message
        error stop 'allocatable frontend'
    end if
    do i=1,3
        call execute_program(p,d)
        if(d%code/=0) then
            print *,d%message
            error stop 'allocatable module run reset'
        end if
    end do
    do i=1,9
        call fresh()
        a=0;q=0;stat=0
        do j=1,p%nc
            if(p%code(j)%op==op_allocate) a=j
            if(p%code(j)%op==op_deallocate) q=j
        end do
        stat=p%code(a)%a
        select case(i)
        case(1)
            p%symbols(1)%is_allocatable=.false.
        case(2)
            p%symbols(1)%assumed_shape=.true.
        case(3)
            p%symbols(1)%lower_bound=2
        case(4)
            p%symbols(1)%rank=3
        case(5)
            p%code(a)%items(2)=0
        case(6)
            p%code(a)%items=[p%code(a)%items,0]
        case(7)
            p%expressions(stat)%parenthesized=.true.
        case(8)
            p%code(q)%items=[1]
        case(9)
            p%symbols(1)%is_automatic=.true.
        end select
        call verify_frontend(source,p,d)
        if(d%code/=1) then
            print *,i,d%code
            error stop 'allocation adapter mutation escaped'
        end if
        d=diagnostic_t()
        call execute_program(p,d)
        if(d%code/=2) then
            print *,i,d%code
            error stop 'allocation runtime mutation escaped'
        end if
    end do
    print '(a)','PASS: allocatable run reset and 18 adapter/runtime mutation rejections'
contains
    subroutine fresh()
        d=diagnostic_t()
        call parse_subset(source,p,d)
        if(d%code/=0) then
            print *,d%message
            error stop 'allocatable parser'
        end if
    end subroutine
end program
