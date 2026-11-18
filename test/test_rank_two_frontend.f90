! SPDX-License-Identifier: MIT
! Rank-two support must preserve the adapter's independent AST/IR contracts.
program test_rank_two_frontend
    use, intrinsic :: iso_fortran_env, only: int64
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        'integer :: a(-1:0,3:5), b(2,3), i'//nl//'logical :: flags(2,3)'//nl// &
        'a=1'//nl//'b=+a'//nl//'b=max(a,abs(-b),3)'//nl//'flags=a>0'//nl// &
        'a(-1,3)=7'//nl//'i=a(-1,3)'//nl// &
        'print *,a,b,flags,size(a),size(a,2),lbound(a,2),ubound(a,2)'//nl//'end program p'
    character(*),parameter::dummy_source='module m'//nl//'implicit none'//nl//'contains'//nl// &
        'subroutine fill(x)'//nl//'integer, intent(inout) :: x(-2:,4:)'//nl// &
        'x=x+1'//nl//'x(-2,4)=9'//nl//'end subroutine fill'//nl// &
        'integer function first(x) result(value)'//nl//'integer, intent(in) :: x(:,:)'//nl// &
        'integer :: i,j,tmp(2,3)'//nl//'tmp=1'//nl//'value=0'//nl// &
        'do j=1,size(x,2)'//nl//'do i=1,size(x,1)'//nl//'value=value+x(i,j)'//nl// &
        'end do'//nl//'end do'//nl//'value=value+tmp(1,1)+lbound(x,2)+ubound(x,2)'//nl//'end function first'//nl// &
        'end module m'//nl//'program p'//nl//'use m'//nl//'implicit none'//nl// &
        'integer :: a(2,3)'//nl//'a=1'//nl//'call fill(a)'//nl//'print *,first(a)'//nl//'end program p'
    integer::which,e,pc,j,s
    do which=1,17
        call parse_subset(source,p,d)
        call require_ok('explicit-shape baseline parse')
        select case(which)
        case(2)
            p%symbols(1)%lower_bound2=4_int64
        case(3)
            p%symbols(1)%upper_bound2=6_int64
        case(4)
            p%symbols(1)%lower_expr2=0
        case(5)
            p%expressions(p%symbols(1)%upper_expr2)%value%i=6_int64
        case(6)
            p%symbols(1)%rank=1
        case(7:10)
            do e=1,p%ne
                if(p%expressions(e)%rank/=2) cycle
                select case(which)
                case(7)
                    p%expressions(e)%dims=[3_int64,2_int64,1_int64]
                case(8)
                    p%expressions(e)%extent=7_int64
                case(9)
                    p%expressions(e)%rank=1
                case(10)
                    p%expressions(e)%dims=-1_int64
                end select
                exit
            end do
            if(e>p%ne) error stop 'missing rank-two expression'
        case(11:13)
            do e=1,p%ne
                if(p%expressions(e)%kind/=ex_element) cycle
                select case(which)
                case(11)
                    p%expressions(e)%right=0
                case(12)
                    p%expressions(e)%right=p%expressions(e)%left
                case(13)
                    p%expressions(e)%right=e
                end select
                exit
            end do
            if(e>p%ne) error stop 'missing rank-two element'
        case(14:16)
            do pc=1,p%nc
                if(p%code(pc)%op/=op_assign.or.p%code(pc)%b==0) cycle
                select case(which)
                case(14)
                    p%code(pc)%d=0
                case(15)
                    p%code(pc)%d=p%code(pc)%b
                case(16)
                    p%code(pc)%b=0
                end select
                exit
            end do
            if(pc>p%nc) error stop 'missing rank-two target'
        case(17)
            ! Scalar caches must not carry undeclared rank-two dimensions.
            p%expressions(p%symbols(1)%upper_expr)%dims=[1_int64,1_int64,1_int64]
        end select
        call verify_frontend(source,p,d)
        if(which==1) then
            call require_ok('explicit-shape baseline verification')
        else
            call require_rejected(which)
        end if
    end do
    do which=1,5
        call parse_subset(dummy_source,p,d)
        call require_ok('assumed-shape baseline parse')
        s=0
        do j=1,p%ns
            if(p%symbols(j)%rank==2.and.p%symbols(j)%is_dummy) then
                s=j;exit
            end if
        end do
        if(s==0) error stop 'missing rank-two dummy'
        select case(which)
        case(2)
            p%symbols(s)%upper_bound2=p%symbols(s)%upper_bound2+1_int64
        case(3)
            p%symbols(s)%upper_expr2=p%symbols(s)%lower_expr2
        case(4)
            p%symbols(s)%rank=1
        case(5)
            do e=1,p%ne
                if(p%expressions(e)%kind/=ex_variable.or.p%expressions(e)%symbol/=s) cycle
                p%expressions(e)%dims=[2_int64,3_int64,1_int64]
                exit
            end do
            if(e>p%ne) error stop 'missing rank-two dummy reference'
        end select
        call verify_frontend(dummy_source,p,d)
        if(which==1) then
            call require_ok('assumed-shape baseline verification')
        else
            call require_rejected(which+16)
        end if
    end do
    ! Equal total sizes do not imply equal shapes. Both source and guarded
    ! declaration caches agree here; independent assignment conformance wins.
    call parse_subset('integer :: a(2,3), b(2,3)'//nl//'a=b'//nl//'end',p,d)
    call require_ok('same-size shape baseline parse')
    p%symbols(1)%upper_bound=3_int64;p%symbols(1)%upper_bound2=2_int64
    p%expressions(p%symbols(1)%upper_expr)%value%i=3_int64
    p%expressions(p%symbols(1)%upper_expr2)%value%i=2_int64
    call verify_frontend('integer :: a(3,2), b(2,3)'//nl//'a=b'//nl//'end',p,d)
    call require_rejected(22)
    call parse_subset('integer :: a(0,100000)'//nl// &
        'print *,size(a),size(a,2),lbound(a,2),ubound(a,2)'//nl//'end',p,d)
    call require_ok('zero-total large-dimension baseline parse')
    call verify_frontend('integer :: a(0,100000)'//nl// &
        'print *,size(a),size(a,2),lbound(a,2),ubound(a,2)'//nl//'end',p,d)
    call require_ok('zero-total large-dimension baseline verification')
    print '(a)','PASS: rank-two explicit/assumed-shape baselines and 21 independent AST/IR disagreements'
contains
    subroutine require_ok(context)
        character(*),intent(in)::context
        if(d%code==0) return
        print *,context
        if(allocated(d%message)) print *,d%message
        error stop 'rank-two frontend baseline rejected'
    end subroutine
    subroutine require_rejected(mutation)
        integer,intent(in)::mutation
        if(d%code/=0) return
        print *,mutation
        error stop 'rank-two frontend admitted forged IR'
    end subroutine
end program
