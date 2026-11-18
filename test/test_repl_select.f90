! SPDX-License-Identifier: MIT
program test_repl_select
    use, intrinsic::iso_fortran_env,only:int64
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime
    implicit none
    character(*),parameter::nl=new_line('a'),head='program p'//nl//'implicit none'//nl// &
        'integer :: i,n'//nl
    character(:),allocatable::source
    character(32)::number
    type(program_t)::p,q,bad
    type(diagnostic_t)::d
    type(scalar_session_t)::session
    type(value_t)::v
    logical::defined
    integer::checks=0,j,k,entry,arm,finish,frontier
    source=head//'i=2'//nl//'n=0'//nl//'select case(i)'//nl//'case default'//nl// &
        'n=99'//nl//'case(1,2)'//nl//'n=n+7'//nl//'case(4:3)'//nl//'n=66'//nl//'end select'//nl
    call parse(source,p)
    call execute_scalar_session(session,p,d);call check(d%code==0,'retained SELECT')
    call value(7_int64);frontier=scalar_session_frontier(session)
    call parse(source//'print *,n'//nl,q)
    do j=1,3
        call execute_scalar_session(session,q,d,commit=.false.)
        call check(d%code==0.and.scalar_session_frontier(session)==frontier,'read-only repeated query')
    end do
    call parse(source//'n=n+1'//nl,q)
    call execute_scalar_session(session,q,d);call check(d%code==0,'healthy suffix');call value(8_int64)
    entry=0
    do j=1,p%nc
        if(p%code(j)%op==op_select)entry=j
    end do
    arm=entry+1;finish=p%code(entry)%target
    do k=1,20
        bad=p
        select case(k)
        case(1);bad%code(entry)%target=finish+1
        case(2);bad%code(entry)%a=0
        case(3);bad%code(entry)%scope=1
        case(4);bad%code(entry)%b=1
        case(5);bad%code(arm)%target=arm+1
        case(6);bad%code(arm)%a=0
        case(7);bad%code(arm)%a=arm
        case(8);bad%code(arm)%items=[0,0]
        case(9);bad%code(arm)%items=[1]
        case(10);bad%code(arm)%items=[-1,-1]
        case(11);bad%code(arm)%items=[p%ne+1,p%ne+1]
        case(12);bad%code(arm)%scope=1
        case(13);bad%code(arm)%symbol=1
        case(14);bad%code(arm)%format='(I0)'
        case(15);bad%code(arm)%construct_name='bad'
        case(16);deallocate(bad%code(arm)%items)
        case(17);bad%code(arm)%target=finish+1
        case(18);bad%code(finish-1)%target=finish-1
        case(19);bad%code(arm)%b=1
        case(20);bad%code(entry)%items=[1,1]
        end select
        d=diagnostic_t();call validate_scalar_session_program(bad,d)
        call check(d%code/=0,'mutated SELECT rejected')
        call check(.not.scalar_session_tainted(session),'invalid admission leaves healthy state')
    end do
    call value(8_int64)
    ! At most64 alternatives in one SELECT; the65th is rejected by ordinary parse.
    source=head//'i=64'//nl//'n=0'//nl//'select case(i)'//nl
    do j=1,64
        write(number,'(i0)')j
        source=source//'case('//trim(number)//')'//nl//'n='//trim(number)//nl
    end do
    call parse(source//'end select'//nl,p)
    call reset_scalar_session(session);call execute_scalar_session(session,p,d)
    call check(d%code==0,'64 alternatives');call value(64_int64)
    d=diagnostic_t();call parse_subset(source//'case(65)'//nl//'end select'//nl//'end program p'//nl,p,d)
    call check(d%code/=0,'65 alternatives refused')
    ! Closed control frontier is preserved across an empty SELECT.
    source=head//'i=1'//nl//'n=8'//nl//'select case(i)'//nl//'end select'//nl
    call parse(source,p);call reset_scalar_session(session);call execute_scalar_session(session,p,d)
    call check(d%code==0,'empty SELECT');call value(8_int64)
    call parse(source//'n=n+1'//nl,q);call execute_scalar_session(session,q,d)
    call check(d%code==0,'empty SELECT suffix');call value(9_int64)
    print *, 'retained SELECT author checks:',checks
contains
    subroutine check(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        if(.not.ok)then
            print *, 'FAIL: ',label
            if(allocated(d%message))print *,d%message
            error stop 1
        end if
        checks=checks+1
    end subroutine
    subroutine parse(body,prog)
        character(*),intent(in)::body
        type(program_t),intent(out)::prog
        d=diagnostic_t();call parse_subset(body//'end program p'//nl,prog,d)
        if(d%code==0)call verify_frontend(body//'end program p'//nl,prog,d)
        call check(d%code==0,'parse/frontend')
    end subroutine
    subroutine value(expected)
        integer(int64),intent(in)::expected
        d=diagnostic_t();call inspect_scalar_session(session,2,v,defined,d)
        call check(d%code==0.and.defined,'defined value')
        call check(v%i==expected,'correct value')
    end subroutine
end program
