! SPDX-License-Identifier: MIT
program test_rank_two_section_frontend
    use, intrinsic :: iso_fortran_env, only: int64
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        'integer :: a(-1:2,3:6),b(4,4),i,j,k'//nl// &
        'a=1'//nl//'b=2'//nl//'i=-1'//nl//'j=2'//nl//'k=1'//nl// &
        'a(i:j:k,6:3:-1)=b(:,:)'//nl// &
        'a(:,3)=a(:,4)'//nl//'a(1,:)=a(2,:)'//nl// &
        'print *,a(i:j:k,3:6:k),a(a(-1,3):j:k,3:6:k),a(i,:),a(:,j)'//nl// &
        'end program p'
    integer::which,e,pc,child
    do which=1,22
        call parse_subset(source,p,d)
        call require_ok('baseline parse')
        do pc=1,p%nc
            if(p%code(pc)%c/=0) exit
        end do
        e=p%code(pc)%c
        select case(which)
        case(2);p%expressions(e)%rank=1
        case(3);p%expressions(e)%extent=16_int64
        case(4);p%expressions(e)%dims=[4_int64,4_int64,1_int64]
        case(5);p%expressions(e)%left2=0
        case(6);p%expressions(e)%right2=0
        case(7);p%expressions(e)%stride2=0
        case(8);p%expressions(e)%left2=p%expressions(e)%right2
        case(9);p%expressions(e)%right2=p%expressions(e)%left2
        case(10);p%expressions(e)%stride2=p%expressions(e)%left2
        case(11);p%expressions(e)%left2=e
        case(12);p%expressions(e)%right2=e
        case(13);p%expressions(e)%stride2=e
        case(14);p%expressions(e)%triplet(2)=.false.
        case(15);p%expressions(e)%symbol=2
        case(16);p%expressions(e)%typ=ty_real
        case(17);p%code(pc)%d=p%expressions(e)%left
        case(18);p%expressions(e)%stride2=p%ne+1
        case(19:21)
            do e=1,p%ne
                if(p%expressions(e)%kind/=ex_section) cycle
                if(p%expressions(e)%triplet(1)) cycle
                exit
            end do
            if(e>p%ne) error stop 'mixed section absent'
            if(which==19) p%expressions(e)%left=0
            if(which==20) p%expressions(e)%right=p%expressions(e)%left
            if(which==21) p%expressions(e)%triplet=[.true.,.false.,.false.]
        case(22)
            child=p%expressions(e)%left2
            p%expressions(child)%typ=ty_real
        end select
        call verify_frontend(source,p,d)
        if(which==1) then
            call require_ok('baseline verification')
        else if(d%code==0) then
            print *,which
            error stop 'forged rank-two section admitted'
        end if
    end do
    print '(a)','PASS: rank-two section baseline and 21 adapter mutations'
contains
    subroutine require_ok(label)
        character(*),intent(in)::label
        if(d%code==0) return
        print *,label,d%message
        error stop 'rank-two section frontend test failed'
    end subroutine
end program
