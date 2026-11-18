! SPDX-License-Identifier: MIT
! LOGICAL descriptors, default-kind invariants and malformed IR at both boundaries.
program test_logical_allocatables
    use, intrinsic :: iso_fortran_env, only: int64
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: execute_program
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='module m'//nl//'logical,allocatable::v(:,:,:)'//nl//'contains'//nl// &
        'subroutine setup()'//nl//'allocate(v(-1:0,4:4,7:8))'//nl//'v=.true.'//nl//'end subroutine'//nl// &
        'subroutine clean()'//nl//'deallocate(v)'//nl//'end subroutine'//nl//'end module'//nl// &
        'program main'//nl//'use m'//nl//'integer::s'//nl// &
        'if(allocated(v)) error stop 1'//nl//'call setup()'//nl// &
        'if(lbound(v,3)/=7.or.ubound(v,3)/=8) error stop 2'//nl// &
        'if(.not.all(v(:,:,7)).or..not.all(v(:,:,8))) error stop 3'//nl// &
        'allocate(v(1,1,1),stat=s)'//nl//'if(s==0) error stop 4'//nl// &
        'if(lbound(v,3)/=7.or..not.v(0,4,8)) error stop 5'//nl// &
        'call clean()'//nl//'if(allocated(v)) error stop 6'//nl//'end program'
    character(*),parameter::optional_source='program main'//nl//'logical,allocatable::a(:,:,:)'//nl// &
        'call inspect()'//nl//'call inspect(a)'//nl//'allocate(a(1,1,2))'//nl//'a=.true.'//nl// &
        'call inspect(a)'//nl//'contains'//nl//'subroutine inspect(x)'//nl// &
        'logical,allocatable,optional,intent(in)::x(:,:,:)'//nl// &
        'if(present(x)) then'//nl//'if(allocated(x)) then'//nl// &
        'if(.not.x(1,1,2)) error stop 7'//nl//'end if'//nl//'end if'//nl// &
        'end subroutine'//nl//'end program'
    type(program_t)::p
    type(diagnostic_t)::d
    integer::i,j,a,q
    call fresh()
    call verify_frontend(source,p,d)
    call require_ok('frontend')
    do i=1,3
        d=diagnostic_t()
        call execute_program(p,d)
        call require_ok('LOGICAL module descriptor reset')
    end do
    do i=1,16
        call fresh()
        a=0;q=0
        do j=1,p%nc
            if(p%code(j)%op==op_allocate.and.a==0) a=j
            if(p%code(j)%op==op_deallocate) q=j
        end do
        if(a==0.or.q==0.or.size(p%code(a)%items)/=6) error stop 'missing LOGICAL allocation metadata'
        select case(i)
        case(1);p%symbols(1)%rank=4
        case(2);p%symbols(1)%lower_bound3=2_int64
        case(3);p%symbols(1)%upper_bound3=2_int64
        case(4);p%symbols(1)%lower_expr3=p%code(a)%items(5)
        case(5);p%symbols(1)%upper_expr3=p%code(a)%items(6)
        case(6);p%symbols(1)%is_allocatable=.false.
        case(7);p%symbols(1)%assumed_shape=.true.
        case(8);p%code(a)%items(6)=0
        case(9);p%code(a)%items=p%code(a)%items(:4)
        case(10);p%code(a)%items=[p%code(a)%items,0,0]
        case(11);p%code(a)%items(5)=p%ne+1
        case(12);p%code(q)%items=[1]
        case(13);p%symbols(1)%is_automatic=.true.
        case(14);p%symbols(1)%typ=ty_derived_base+1
        case(15);p%code(a)%b=p%code(a)%items(6)
        case(16);p%symbols(1)%real_kind=8
        end select
        call verify_frontend(source,p,d)
        if(d%code/=1) then
            print *,i,d%code
            error stop 'LOGICAL allocation adapter mutation escaped'
        end if
        d=diagnostic_t()
        call execute_program(p,d)
        if(d%code/=2) then
            print *,i,d%code
            error stop 'LOGICAL allocation runtime mutation escaped'
        end if
    end do
    d=diagnostic_t()
    call parse_subset(optional_source,p,d)
    call require_ok('OPTIONAL parse')
    call verify_frontend(optional_source,p,d)
    call require_ok('OPTIONAL frontend')
    call execute_program(p,d)
    call require_ok('OPTIONAL runtime')
    print '(a)','PASS: LOGICAL allocation reset, OPTIONAL descriptors and 32 adapter/runtime mutation rejections'
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
        error stop 'unexpected LOGICAL allocatable diagnostic'
    end subroutine
end program
