! SPDX-License-Identifier: MIT
program test_repl_loops
    use, intrinsic :: iso_fortran_env, only: int64
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_runtime
    implicit none
    character(*),parameter :: nl=new_line('a')
    character(*),parameter :: head='program p'//nl//'implicit none'//nl// &
        'integer :: i,j,s,n,a(3)'//nl
    type(program_t) :: p,q,bad
    type(scalar_session_t) :: session,trial
    type(diagnostic_t) :: d
    type(value_t) :: v
    logical :: defined
    character(:),allocatable :: source
    integer :: checks=0,k,entry,last,branch,outside,assignment,frontier
    source=head//'s=0'//nl//'n=3'//nl//'if (.true.) s=0'//nl// &
        'do i=1,n'//nl//'if (i==2) then'//nl//'s=s+10'//nl// &
        'else'//nl//'s=s+i'//nl//'endif'//nl//'a(i)=s'//nl//'enddo'//nl
    call parse(source,p)
    call execute_scalar_session(session,p,d);call check(d%code==0,'counted IF/array loop')
    call value(3,14_int64);call value(1,4_int64)
    frontier=scalar_session_frontier(session)
    call execute_scalar_session(session,p,d);call check(d%code==0,'empty suffix')
    call value(3,14_int64)
    call parse(source//'print *, s'//nl,q)
    do k=1,2
        call execute_scalar_session(session,q,d,commit=.false.)
        call check(d%code==0.and.scalar_session_frontier(session)==frontier,'readonly loop query')
        call value(3,14_int64)
    end do
    entry=0;last=0;branch=0;outside=0;assignment=0
    do k=1,p%nc
        select case(p%code(k)%op)
        case(op_do);entry=k
        case(op_next);last=k
        case(op_branch)
            if(entry==0)then
                outside=k
            else
                branch=k
            end if
        case(op_assign)
            if(entry>0.and.p%code(k)%symbol==3)assignment=k
        end select
    end do
    call check(min(entry,last,branch,outside,assignment)>0,'IR sites found')
    do k=1,18
        bad=p
        select case(k)
        case(1);bad%code(entry)%target=entry+1
        case(2);bad%code(entry)%target=p%nc+2
        case(3);bad%code(entry)%d=1
        case(4);bad%code(entry)%d=2
        case(5);bad%code(entry)%construct_name='named'
        case(6);bad%code(entry)%a=0
        case(7);bad%code(entry)%c=p%ne+1
        case(8);bad%code(entry)%a=p%code(branch)%a
        case(9);bad%code(entry)%symbol=5
        case(10);bad%code(last)%a=0
        case(11);bad%code(last)%target=1
        case(12);bad%code(last)%symbol=2
        case(13);bad%code(last)%b=1
        case(14);bad%code(last)%d=1
        case(15);bad%code(branch)%target=last+1
        case(16);bad%code(outside)%target=entry+1
        case(17);bad%code(assignment)%symbol=1
        case(18);bad%code(branch)%op=op_jump;bad%code(branch)%a=0;bad%code(branch)%target=entry
        end select
        call rejected(bad)
    end do
    ! Forged query exit cannot bypass its ephemeral final print.
    bad=q;bad%code(entry)%target=q%nc+1
    d=diagnostic_t();call validate_scalar_session_query(bad,p%nc,d)
    call check(d%code/=0,'DO query bypass rejected')
    call value(3,14_int64)
    call parse(source//'do j=3,1,-1'//nl//'s=s+j'//nl//'end do'//nl,q)
    call execute_scalar_session(session,q,d);call check(d%code==0,'appended descending loop')
    call value(3,20_int64);call value(2,0_int64)
    call execute_scalar_session(session,q,d);call check(d%code==0,'no replay appended loop')
    call value(3,20_int64)

    call fresh(head//'s=0'//nl//'do i=1,3'//nl//'do j=1,2'//nl// &
        's=s+1'//nl//'end do'//nl//'end do'//nl)
    call value(3,6_int64)
    ! Malformed nested edges/reuse must reject without execution.
    entry=0;last=0
    do k=1,p%nc
        if(p%code(k)%op/=op_do)cycle
        if(entry==0)then
            entry=k
        else
            last=k
        end if
    end do
    bad=p;bad%code(last)%target=bad%code(entry)%target
    call rejected(bad)
    bad=p;bad%code(last)%symbol=1;bad%code(bad%code(last)%target-1)%symbol=1
    call rejected(bad)
    call fresh(head//'s=0'//nl//'n=3'//nl//'do i=1,n'//nl//'n=0'//nl// &
        's=s+1'//nl//'end do'//nl)
    call value(3,3_int64)
    call fresh(head//'s=9'//nl//'do i=3,1'//nl//'s=0'//nl//'enddo'//nl)
    call value(3,9_int64);call value(1,3_int64)
    call fresh(head//'do i=1,5,2'//nl//'end do'//nl)
    call value(1,7_int64)
    call fresh('program p'//nl//'integer(8)::i'//nl// &
        'do i=2147483648_8,2147483649_8'//nl//'enddo'//nl)
    call value(1,2147483650_int64)
    call runtime_failure(head//'do i=1,3,0'//nl//'enddo'//nl,1000_int64)
    call runtime_failure(head//'do i=1,n'//nl//'enddo'//nl,1000_int64)
    call runtime_failure(head//'do i=2147483647,2147483647'//nl//'enddo'//nl,1000_int64)
    call runtime_failure(head//'do i=1,100'//nl//'enddo'//nl,3_int64)
    call runtime_failure(head//'do i=1,4'//nl//'a(i)=1'//nl//'enddo'//nl,1000_int64)
    print *, 'retained counted loop checks: ',checks
contains
    subroutine parse(text,prog)
        character(*),intent(in)::text
        type(program_t),intent(out)::prog
        d=diagnostic_t();call parse_subset(text//'end program'//nl,prog,d)
        call check(d%code==0,'fixture parses')
    end subroutine
    subroutine fresh(text)
        character(*),intent(in)::text
        call reset_scalar_session(session);call parse(text,p)
        call execute_scalar_session(session,p,d);call check(d%code==0,'fresh loop executes')
    end subroutine
    subroutine value(index,expected)
        integer,intent(in)::index
        integer(int64),intent(in)::expected
        d=diagnostic_t();call inspect_scalar_session(session,index,v,defined,d)
        call check(d%code==0.and.defined,'scalar retained')
        call check(v%i==expected,'retained value correct')
    end subroutine
    subroutine rejected(prog)
        type(program_t),intent(in)::prog
        integer::old
        old=scalar_session_frontier(session)
        d=diagnostic_t();call validate_scalar_session_program(prog,d)
        call check(d%code/=0,'forged loop admission rejects')
        d=diagnostic_t();call execute_scalar_session(session,prog,d)
        call check(d%code/=0.and..not.scalar_session_tainted(session),'rejection not tainted')
        call check(scalar_session_frontier(session)==old,'rejection preserves frontier')
    end subroutine
    subroutine runtime_failure(text,steps)
        character(*),intent(in)::text
        integer(int64),intent(in)::steps
        call reset_scalar_session(trial);call parse(text,q)
        call execute_scalar_session(trial,q,d,max_steps=steps)
        call check(d%code/=0.and.scalar_session_tainted(trial),'loop runtime failure taints')
        d=diagnostic_t();call execute_scalar_session(trial,q,d)
        call check(d%code/=0,'failed loop cannot retry')
    end subroutine
    subroutine check(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        if(.not.ok)then
            print *, 'FAIL ',label
            if(allocated(d%message))print *, d%message
            stop 1
        end if
        checks=checks+1
    end subroutine
end program
