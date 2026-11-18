! SPDX-License-Identifier: MIT
! Adversarial IR tests: validate before executing or altering a retained session.
program test_repl_branch_admission
    use, intrinsic :: iso_fortran_env, only: int64
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_runtime, only: scalar_session_t, execute_scalar_session, &
        inspect_scalar_session, scalar_session_frontier, scalar_session_tainted, &
        validate_scalar_session_program, validate_scalar_session_query
    implicit none
    character(*), parameter :: nl=new_line('a')
    character(*), parameter :: source='program p'//nl//'implicit none'//nl// &
        'integer :: i'//nl//'i=10'//nl//'if (.true.) then'//nl// &
        'i=i+1'//nl//'else'//nl//'i=i+100'//nl//'end if'//nl
    type(program_t) :: base, query, bad
    type(scalar_session_t) :: session
    type(diagnostic_t) :: d
    type(value_t) :: v
    logical :: defined
    integer :: branch, jump, pc, k, n, target, frontier, checks
    integer :: sites(2)
    checks=0
    call parse(source,base)
    call parse(source//'print *, i'//nl,query)
    branch=0
    jump=0
    do pc=1,base%nc
        if(base%code(pc)%op==op_branch)branch=pc
        if(base%code(pc)%op==op_jump)jump=pc
    end do
    call expect(branch>1.and.jump>branch,'fixture has branch and jump after assignment')
    sites=[branch,jump]
    d=diagnostic_t()
    call execute_scalar_session(session,base,d)
    call expect(d%code==0,'baseline executes')
    frontier=scalar_session_frontier(session)
    call unchanged()

    do k=1,size(sites)
        pc=sites(k)
        do n=1,3
            select case(n)
            case(1);target=-1
            case(2);target=0
            case(3);target=huge(target)
            end select
            bad=query
            bad%code(pc)%target=target
            d=diagnostic_t()
            call validate_scalar_session_program(bad,d)
            call expect(d%code/=0,'invalid branch/jump target rejected by admission')
            d=diagnostic_t()
            call execute_scalar_session(session,bad,d,commit=.false.)
            call expect(d%code/=0,'invalid target rejected by readonly execution')
            call unchanged()
            d=diagnostic_t()
            call execute_scalar_session(session,bad,d)
            call expect(d%code/=0,'invalid target rejected by committing execution')
            call unchanged()
        end do

        ! Both immediate-next and one-past-program are legal forward targets.
        bad=base
        bad%code(pc)%target=pc+1
        d=diagnostic_t()
        call validate_scalar_session_program(bad,d)
        call expect(d%code==0,'immediate-next forward target admitted')
        bad%code(pc)%target=base%nc+1
        d=diagnostic_t()
        call validate_scalar_session_program(bad,d)
        call expect(d%code==0,'one-past-program target admitted')

        ! A legal full-program edge must not bypass the ephemeral query PRINT.
        ! Check both opcodes, including the branch not taken in this fixture.
        bad=query
        bad%code(pc)%target=query%nc+1
        d=diagnostic_t()
        call validate_scalar_session_program(bad,d)
        call expect(d%code==0,'query bypass is otherwise valid forward IR')
        d=diagnostic_t()
        call validate_scalar_session_query(bad,base%nc,d)
        call expect(d%code/=0,'query-only validator rejects bypass edge')
        d=diagnostic_t()
        call execute_scalar_session(session,bad,d,commit=.false.)
        call expect(d%code/=0,'query bypass cannot execute')
        call unchanged()

        ! A valid target alteration still cannot rewrite a committed prefix.
        bad=query
        bad%code(pc)%target=pc+1
        call expect(bad%code(pc)%target/=base%code(pc)%target,'prefix mutation is real')
        d=diagnostic_t()
        call validate_scalar_session_query(bad,base%nc,d)
        call expect(d%code==0,'prefix mutation is locally admissible')
        d=diagnostic_t()
        call execute_scalar_session(session,bad,d,commit=.false.)
        call expect(d%code/=0,'exact retained prefix rejects changed forward edge')
        call unchanged()
    end do

    ! Rejections neither poison the session nor commit a query frontier.
    do n=1,2
        d=diagnostic_t()
        call validate_scalar_session_query(query,base%nc,d)
        call expect(d%code==0,'unchanged query admitted after failures')
        call execute_scalar_session(session,query,d,commit=.false.)
        call expect(d%code==0,'unchanged query runs after failures')
        call unchanged()
    end do
    print *, 'branch admission checks: ',checks
contains
    subroutine parse(text,prog)
        character(*),intent(in) :: text
        type(program_t),intent(out) :: prog
        d=diagnostic_t()
        call parse_subset(text//'end program'//nl,prog,d)
        call expect(d%code==0,'fixture parses')
    end subroutine
    subroutine unchanged()
        call expect(.not.scalar_session_tainted(session),'admission failure does not taint')
        call expect(scalar_session_frontier(session)==frontier,'frontier unchanged')
        d=diagnostic_t()
        call inspect_scalar_session(session,1,v,defined,d)
        call expect(d%code==0.and.defined,'retained scalar readable')
        call expect(v%i==11_int64,'retained scalar unchanged without replay')
    end subroutine
    subroutine expect(ok,label)
        logical,intent(in) :: ok
        character(*),intent(in) :: label
        if(.not.ok)then
            print *, 'FAIL ',label
            if(allocated(d%message))print *,d%message
            stop 1
        end if
        checks=checks+1
    end subroutine
end program test_repl_branch_admission
