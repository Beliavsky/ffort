! SPDX-License-Identifier: MIT
! Independent adapter validation must reject forged third-axis metadata.
program test_rank_three_frontend
    use, intrinsic :: iso_fortran_env, only: int64
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        'integer :: aa(-1:0,3:5,7:10),bb(2,3,4),i'//nl// &
        'aa=1'//nl//'bb=max(abs(-aa),3)'//nl//'aa(-1,3,7)=9'//nl// &
        'i=aa(-1,3,7)'//nl//'aa(:,:,10:7:-1)=aa(:,:,7:10)'//nl// &
        'print *,aa(:,3,7),aa(:,:,7),aa(:,:,:),bb'//nl// &
        'print *,size(aa,3),lbound(aa,3),ubound(aa,3)'//nl//'end program p'
    character(*),parameter::dummy_source='module m'//nl//'implicit none'//nl//'contains'//nl// &
        'subroutine fill(xx,n,m,l)'//nl//'integer,intent(in) :: n,m,l'//nl//'integer,intent(inout) :: xx(-2:,4:,7:)'//nl// &
        'integer :: tmp(n,m,l)'//nl// &
        'tmp=xx+1'//nl//'xx=tmp'//nl//'xx(-2,4,7)=9'//nl//'end subroutine fill'//nl// &
        'function twice(xx) result(rr)'//nl//'integer,intent(in) :: xx(:,:,:)'//nl// &
        'integer :: rr(size(xx,1),size(xx,2),size(xx,3))'//nl// &
        'rr=xx*2'//nl//'end function twice'//nl//'end module m'//nl// &
        'program p'//nl//'use m'//nl//'implicit none'//nl// &
        'integer :: aa(2,3,4)'//nl//'aa=1'//nl//'call fill(aa,2,3,4)'//nl// &
        'aa=twice(aa)'//nl//'print *,aa'//nl//'end program p'
    integer::which,e,pc,j,s
    do which=1,25
        call parse_subset(source,p,d)
        call require_ok('explicit-shape baseline parse')
        select case(which)
        case(2)
            p%symbols(1)%lower_bound3=8_int64
        case(3)
            p%symbols(1)%upper_bound3=11_int64
        case(4)
            p%symbols(1)%lower_expr3=0
        case(5)
            p%expressions(p%symbols(1)%upper_expr3)%value%i=11_int64
        case(6)
            p%symbols(1)%rank=4
        case(7:10)
            do e=1,p%ne
                if(p%expressions(e)%rank/=3) cycle
                select case(which)
                case(7)
                    p%expressions(e)%dims=[4_int64,3_int64,2_int64]
                case(8)
                    p%expressions(e)%extent=25_int64
                case(9)
                    p%expressions(e)%rank=2
                case(10)
                    p%expressions(e)%dims(3)=-1_int64
                end select
                exit
            end do
            if(e>p%ne) error stop 'missing rank-three expression'
        case(11:14)
            do e=1,p%ne
                if(p%expressions(e)%kind/=ex_element) cycle
                select case(which)
                case(11)
                    p%expressions(e)%third=0
                case(12)
                    p%expressions(e)%third=p%expressions(e)%left
                case(13)
                    p%expressions(e)%third=e
                case(14)
                    p%expressions(e)%left3=p%expressions(e)%third
                end select
                exit
            end do
            if(e>p%ne) error stop 'missing rank-three element'
        case(15:18)
            do pc=1,p%nc
                if(p%code(pc)%op/=op_assign.or.p%code(pc)%b==0) cycle
                select case(which)
                case(15)
                    p%code(pc)%third=0
                case(16)
                    p%code(pc)%third=p%code(pc)%b
                case(17)
                    p%code(pc)%b=0
                case(18)
                    p%code(pc)%third=p%ne+1
                end select
                exit
            end do
            if(pc>p%nc) error stop 'missing rank-three target'
        case(19:23)
            do e=1,p%ne
                if(p%expressions(e)%kind/=ex_section.or.p%expressions(e)%stride3==0) cycle
                select case(which)
                case(19)
                    p%expressions(e)%triplet(3)=.false.
                case(20)
                    p%expressions(e)%left3=0
                case(21)
                    p%expressions(e)%right3=p%expressions(e)%left3
                case(22)
                    p%expressions(e)%stride3=e
                case(23)
                    p%expressions(e)%third=p%expressions(e)%left3
                end select
                exit
            end do
            if(e>p%ne) error stop 'missing third-axis section'
        case(24)
            p%expressions(p%symbols(1)%upper_expr)%dims(3)=1_int64
        case(25)
            p%expressions(p%symbols(1)%upper_expr)%third=1
        end select
        call verify_frontend(source,p,d)
        if(which==1) then
            call require_ok('explicit-shape baseline verification')
        else
            call require_rejected(which)
        end if
    end do
    do which=1,7
        call parse_subset(dummy_source,p,d)
        call require_ok('assumed-shape and automatic baseline parse')
        s=0
        do j=1,p%ns
            if(p%symbols(j)%rank==3.and.p%symbols(j)%is_dummy) then
                s=j;exit
            end if
        end do
        if(s==0) error stop 'missing rank-three dummy'
        select case(which)
        case(2)
            p%symbols(s)%upper_bound3=p%symbols(s)%upper_bound3+1_int64
        case(3)
            p%symbols(s)%upper_expr3=p%symbols(s)%lower_expr3
        case(4)
            p%symbols(s)%rank=2
        case(5)
            do e=1,p%ne
                if(p%expressions(e)%kind/=ex_variable.or.p%expressions(e)%symbol/=s) cycle
                p%expressions(e)%dims=[2_int64,3_int64,4_int64]
                exit
            end do
            if(e>p%ne) error stop 'missing rank-three dummy reference'
        case(6:7)
            do j=1,p%ns
                if(.not.p%symbols(j)%is_automatic.or.p%symbols(j)%rank/=3) cycle
                if(which==6) p%symbols(j)%upper_expr3=0
                if(which==7) p%symbols(j)%upper_expr3=p%symbols(j)%upper_expr2
                exit
            end do
            if(j>p%ns) error stop 'missing rank-three automatic array'
        end select
        call verify_frontend(dummy_source,p,d)
        if(which==1) then
            call require_ok('assumed-shape and automatic baseline verification')
        else
            call require_rejected(which+24)
        end if
    end do
    ! Keep total elements equal while changing first and third dimensions.
    call parse_subset('integer :: aa(2,3,4),bb(2,3,4)'//nl//'aa=bb'//nl//'end',p,d)
    call require_ok('same-size shape baseline parse')
    p%symbols(1)%upper_bound=4_int64;p%symbols(1)%upper_bound3=2_int64
    p%expressions(p%symbols(1)%upper_expr)%value%i=4_int64
    p%expressions(p%symbols(1)%upper_expr3)%value%i=2_int64
    call verify_frontend('integer :: aa(4,3,2),bb(2,3,4)'//nl//'aa=bb'//nl//'end',p,d)
    call require_rejected(32)
    print '(a)','PASS: rank-three adapter baselines and 31 independent metadata disagreements'
contains
    subroutine require_ok(context)
        character(*),intent(in)::context
        if(d%code==0) return
        print *,context
        if(allocated(d%message)) print *,d%message
        error stop 'rank-three frontend baseline rejected'
    end subroutine
    subroutine require_rejected(mutation)
        integer,intent(in)::mutation
        if(d%code/=0) return
        print *,mutation
        error stop 'rank-three frontend admitted forged IR'
    end subroutine
end program test_rank_three_frontend
