! SPDX-License-Identifier: MIT
program test_bare_do
    use, intrinsic::iso_fortran_env,only:int64
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        'integer::i,n'//nl//'n=0'//nl//'outer: do'//nl//'n=n+1'//nl// &
        'if(n==3) exit outer'//nl//'do i=1,4'//nl//'cycle outer'//nl// &
        'end do'//nl//'end do outer'//nl//'i=8'//nl// &
        'if(n/=3.or.i/=8) error stop 1'//nl//'end program'
    character(*),parameter::empty='program p'//nl//'implicit none'//nl// &
        'do'//nl//'end do'//nl//'end program'
    integer::which,j,outer,inner,cy,ex,back,iback,checks
    integer(int64)::budget
    checks=0
    do which=1,19
        call baseline()
        select case(which)
        case(2);p%code(outer)%d=0
        case(3);p%code(outer)%d=2
        case(4);p%code(outer)%symbol=p%code(inner)%symbol
        case(5);p%code(outer)%a=p%code(inner)%a
        case(6);p%code(outer)%b=p%code(inner)%b
        case(7);p%code(outer)%c=p%code(inner)%a
        case(8);p%code(outer)%construct_name='wrong'
        case(9);p%code(cy)%a=inner
        case(10);p%code(cy)%target=outer+1
        case(11);p%code(ex)%a=inner
        case(12);p%code(ex)%target=back
        case(13);p%code(back)%a=inner
        case(14);p%code(back)%target=inner+1
        case(15);p%code(back)%d=0
        case(16);p%code(back)%symbol=p%code(inner)%symbol
        case(17);p%code(inner)%d=1
        case(18);p%code(iback)%d=1
        case(19);p%code(outer)%target=p%nc+1
        end select
        call verify_frontend(source,p,d)
        call expect(which==1,'adapter',which)
    end do
    do which=1,19
        call baseline()
        select case(which)
        case(2);p%code(outer)%d=0;p%code(back)%d=0
        case(3);p%code(outer)%d=2;p%code(back)%d=2
        case(4);p%code(outer)%symbol=p%code(inner)%symbol;p%code(back)%symbol=p%code(inner)%symbol
        case(5);p%code(outer)%a=p%code(inner)%a
        case(6);p%code(outer)%b=p%code(inner)%b
        case(7);p%code(outer)%c=p%code(inner)%a
        case(8);p%code(outer)%target=outer
        case(9);p%code(outer)%target=p%nc+2
        case(10);p%code(back)%a=inner
        case(11);p%code(back)%target=inner+1
        case(12);p%code(back)%d=0
        case(13);p%code(back)%symbol=p%code(inner)%symbol
        case(14);p%code(cy)%target=outer+1
        case(15);p%code(cy)%a=0
        case(16);p%code(ex)%target=back
        case(17);p%code(ex)%a=0
        case(18);p%code(inner)%d=1;p%code(iback)%d=1
        case(19);p%code(iback)%target=outer+1
        end select
        call execute_program(p,d,max_steps=200_int64)
        call expect(which==1,'runtime',which)
    end do
    do which=1,3
        call parse_subset(empty,p,d)
        call verify_frontend(empty,p,d)
        if(d%code/=0) error stop 'empty bare loop frontend failed'
        budget=int(which-1,int64)
        call execute_program(p,d,budget_remaining=budget)
        if(d%code/=2.or.budget/=0_int64) error stop 'bare loop did not exhaust exact budget'
        if(index(d%message,'execution step limit exceeded')==0) error stop 'wrong bare loop budget error'
        checks=checks+1
    end do
    print '(a,i0,a)','PASS: ',checks,' bare DO adapter/runtime and budget checks'
contains
    subroutine baseline()
        call parse_subset(source,p,d)
        if(d%code/=0) then
            print *,d%message
            error stop 'bare DO baseline parse'
        end if
        outer=0;inner=0;cy=0;ex=0
        do j=1,p%nc
            if(p%code(j)%op==op_do) then
                if(outer==0) then
                    outer=j
                else
                    inner=j
                end if
            end if
            if(p%code(j)%op==op_cycle) cy=j
            if(p%code(j)%op==op_exit) ex=j
        end do
        back=p%code(outer)%target-1;iback=p%code(inner)%target-1
    end subroutine
    subroutine expect(success,stage,number)
        logical,intent(in)::success
        character(*),intent(in)::stage
        integer,intent(in)::number
        checks=checks+1
        if((success.and.d%code/=0).or.(.not.success.and.d%code==0)) then
            print *,stage,number,d%code
            if(allocated(d%message)) print *,d%message
            error stop 'bare DO mutation expectation failed'
        end if
        if(stage=='runtime'.and..not.success.and.d%code/=2) error stop 'incorrect runtime error class'
    end subroutine
end program
