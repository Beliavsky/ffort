! SPDX-License-Identifier: MIT
program test_where
    use, intrinsic :: iso_fortran_env, only:int64
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        'integer::a(4)=[0,2,0,4],b(4)=0'//nl// &
        'where(a==0)'//nl//'b=-1'//nl//'elsewhere(8/a>2)'//nl//'b=8/a'//nl// &
        'elsewhere'//nl//'b=9'//nl//'end where'//nl// &
        'if(any(b/=[-1,4,-1,9])) error stop 1'//nl//'end program'
    character(*),parameter::pure_source='program p'//nl//'integer::a(2)=[1,2]'//nl// &
        'where(a>0) a=f(a)'//nl//'contains'//nl//'elemental integer function f(x)'//nl// &
        'integer,intent(in)::x'//nl//'f=x'//nl//'end function'//nl//'end program'
    integer::which,entry,j,arm,body,checks
    checks=0
    do which=0,18
        call baseline()
        call mutate(which)
        call verify_frontend(source,p,d)
        call expect((d%code==0).eqv.(which==0),'adapter mutation',which)
    end do
    do which=0,18
        call baseline()
        call mutate(which)
        call execute_program(p,d)
        call expect((d%code==0).eqv.(which==0),'runtime mutation',which)
        if(which/=0) call expect(d%code==2,'checked runtime status',which)
    end do
    call parse_subset(pure_source,p,d)
    call expect(d%code==0,'pure source parses',0)
    p%procedures(1)%is_pure=.false.
    call execute_program(p,d)
    call expect(d%code==2,'runtime purity guard',0)
    call baseline()
    call execute_program(p,d,max_steps=10_int64)
    call expect(d%code==2,'execution budget',0)
    print '(a,i0,a)','PASS: WHERE semantic baselines and ',checks,' adapter/runtime checks'
contains
    subroutine mutate(which)
        integer,intent(in)::which
        select case(which)
        case(1);p%code(entry)%a=0
        case(2);p%code(entry)%a=p%ne+1
        case(3);p%code(entry)%b=entry
        case(4);p%code(entry)%b=p%nc+2
        case(5);p%code(entry)%target=entry
        case(6);p%code(entry)%target=p%nc+2
        case(7);p%code(entry)%c=1
        case(8);p%code(entry)%d=1
        case(9);p%code(entry)%scope=1
        case(10);p%code(arm)%d=0
        case(11);p%code(arm)%a=p%ne+1
        case(12);p%code(arm)%target=arm
        case(13);p%code(arm)%scope=1
        case(14);p%code(body)%symbol=0
        case(15);p%code(body)%b=1
        case(16);p%code(body)%op=op_return
        case(17);p%code(body)%c=p%ne+1
        case(18);p%code(body)%scope=1
        end select
    end subroutine
    subroutine expect(ok,what,which)
        logical,intent(in)::ok
        character(*),intent(in)::what
        integer,intent(in)::which
        checks=checks+1
        if(ok) return
        print *,trim(what),which,d%code
        if(allocated(d%message)) print *,d%message
        error stop 1
    end subroutine
    subroutine baseline()
        call parse_subset(source,p,d)
        call expect(d%code==0,'baseline parses',0)
        entry=0
        do j=1,p%nc
            if(p%code(j)%op==op_where) entry=j
        end do
        call expect(entry>0,'WHERE emitted',0)
        body=entry+1;arm=p%code(entry)%b
    end subroutine
end program
