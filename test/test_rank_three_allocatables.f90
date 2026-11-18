! SPDX-License-Identifier: MIT
! Independent forged-descriptor checks, not expected output derived from runtime.
program test_rank_three_allocatables
    use, intrinsic :: iso_fortran_env, only: int64
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: execute_program
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='module m'//nl//'integer,allocatable::v(:,:,:)'//nl//'contains'//nl// &
        'subroutine setup()'//nl//'allocate(v(-1:0,4:4,7:8))'//nl//'v=7'//nl//'end subroutine'//nl// &
        'subroutine clean()'//nl//'deallocate(v)'//nl//'end subroutine'//nl//'end module'//nl// &
        'program main'//nl//'use m'//nl//'integer::s'//nl// &
        'if(allocated(v)) error stop 1'//nl//'call setup()'//nl// &
        'if(lbound(v,3)/=7.or.ubound(v,3)/=8.or.sum(v(:,:,7))+sum(v(:,:,8))/=28) error stop 2'//nl// &
        'allocate(v(1,1,1),stat=s)'//nl//'if(s==0) error stop 3'//nl// &
        'if(lbound(v,3)/=7.or.sum(v(:,:,7))+sum(v(:,:,8))/=28) error stop 4'//nl// &
        'call clean()'//nl//'if(allocated(v)) error stop 5'//nl//'end program'
    character(*),parameter::chars='program main'//nl//'character(:),allocatable::v(:,:,:)'//nl// &
        'allocate(character(3)::v(-1:0,4:4,7:8))'//nl//'v="abcd"'//nl// &
        'if(len(v)/=3.or.v(0,4,8)/="abc") error stop 1'//nl// &
        'deallocate(v)'//nl//'end program'
    type(program_t)::p
    type(diagnostic_t)::d
    integer::i,j,a,q,e
    call fresh(source)
    call verify_frontend(source,p,d)
    call require_ok('numeric frontend')
    do i=1,3
        d=diagnostic_t()
        call execute_program(p,d)
        call require_ok('module allocation descriptor reset')
    end do
    do i=1,13
        call fresh(source)
        a=0;q=0
        do j=1,p%nc
            if(p%code(j)%op==op_allocate.and.a==0) a=j
            if(p%code(j)%op==op_deallocate) q=j
        end do
        if(a==0.or.q==0.or.size(p%code(a)%items)/=6) error stop 'missing rank-three allocation metadata'
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
        end select
        call reject_both(source,i)
    end do
    do i=1,7
        call fresh(chars)
        a=0
        do j=1,p%nc
            if(p%code(j)%op==op_allocate) a=j
        end do
        if(a==0) error stop 'missing CHARACTER allocation'
        e=p%code(a)%b
        select case(i)
        case(1)
            call verify_frontend(chars,p,d)
            call require_ok('CHARACTER frontend')
            call execute_program(p,d)
            call require_ok('CHARACTER runtime')
            cycle
        case(2);p%code(a)%b=0
        case(3);p%expressions(e)%typ=ty_real
        case(4);p%symbols(1)%character_len=3
        case(5);p%symbols(1)%length_expr=e
        case(6);p%code(a)%items(6)=p%ne+1
        case(7);p%symbols(1)%upper_bound3=2_int64
        end select
        call reject_both(chars,13+i)
    end do
    print '(a)','PASS: rank-three allocation reset, CHARACTER and 38 adapter/runtime mutation rejections'
contains
    subroutine fresh(text)
        character(*),intent(in)::text
        d=diagnostic_t()
        call parse_subset(text,p,d)
        call require_ok('parse')
    end subroutine
    subroutine require_ok(label)
        character(*),intent(in)::label
        if(d%code==0) return
        print *,label,': ',d%message
        error stop 'rank-three allocatable unexpected diagnostic'
    end subroutine
    subroutine reject_both(text,which)
        character(*),intent(in)::text
        integer,intent(in)::which
        call verify_frontend(text,p,d)
        if(d%code/=1) then
            print *,which,d%code
            error stop 'rank-three allocation adapter mutation escaped'
        end if
        d=diagnostic_t()
        call execute_program(p,d)
        if(d%code/=2) then
            print *,which,d%code
            error stop 'rank-three allocation runtime mutation escaped'
        end if
    end subroutine
end program
