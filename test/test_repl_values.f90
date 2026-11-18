! SPDX-License-Identifier: MIT
program test_repl_values
    use, intrinsic::iso_fortran_env,only:int64
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime
    implicit none
    character(*),parameter::nl=new_line('a'),body='program p'//nl//'implicit none'//nl// &
        'integer, parameter :: n=5'//nl//'integer :: i,a(n)'//nl//'i=7'//nl//'a=3'//nl
    type(program_t)::p,q,bad
    type(diagnostic_t)::d
    type(scalar_session_t)::session
    type(value_t)::v
    integer::j,k,checks=0,root,frontier
    logical::defined
    call parse(body,p)
    call execute_scalar_session(session,p,d);call check(d%code==0,'parameter retained session')
    call inspect_scalar_session(session,1,v,defined,d)
    call check(d%code==0.and.defined.and.v%i==5,'parameter inspection uses immutable cache')
    frontier=scalar_session_frontier(session)
    call parse(body//'print *,n+i+a(n)'//nl,q)
    do j=1,3
        call execute_scalar_session(session,q,d,commit=.false.)
        call check(d%code==0.and.scalar_session_frontier(session)==frontier,'queries preserve frontier')
    end do
    root=p%symbols(1)%initializer_expr
    do k=1,17
        bad=p
        select case(k)
        case(1);bad%symbols(1)%constant_value%i=6
        case(2);bad%symbols(1)%parameter_ready=.false.
        case(3);bad%symbols(1)%initializer_expr=0
        case(4);bad%symbols(1)%constant_value%real_kind=8
        case(5);bad%symbols(1)%constant_value%tag=ty_real
        case(6);bad%symbols(1)%constant_value%s='hidden'
        case(7);bad%symbols(1)%constant_values=[value_t(tag=ty_integer,i=5_int64)]
        case(8);bad%symbols(1)%is_saved=.true.
        case(9);bad%symbols(1)%character_len=5
        case(10);bad%expressions(root)=expr_t(kind=ex_variable,typ=ty_integer,symbol=2)
        case(11);bad%expressions(root)=expr_t(kind=ex_variable,typ=ty_integer,symbol=1)
        case(12);bad%code(1)%symbol=1
        case(13);bad%symbols(1)%rank=1
        case(14);bad%symbols(1)%real_kind=8
        case(15);bad%symbols(1)%initializer_expr=p%ne+1
        case(16);bad%expressions(root)%value%i=6
        case(17);bad%symbols(1)%constant_value%r=1.0
        end select
        d=diagnostic_t();call validate_scalar_session_program(bad,d)
        call check(d%code/=0,'malformed parameter rejected')
        d=diagnostic_t();call execute_scalar_session(session,bad,d)
        call check(d%code/=0.and..not.scalar_session_tainted(session),'bad input preserves healthy session')
    end do
    d=diagnostic_t();call parse(body//'i=i+1'//nl,q)
    call execute_scalar_session(session,q,d);call check(d%code==0,'healthy suffix')
    call inspect_scalar_session(session,2,v,defined,d)
    call check(defined.and.v%i==8,'suffix executes once')
    call execute_scalar_session(session,q,d)
    call inspect_scalar_session(session,2,v,defined,d)
    call check(d%code==0.and.defined.and.v%i==8,'same suffix not replayed')
    call parse('program p'//nl//'character(3), parameter :: c="a"'//nl,p)
    d=diagnostic_t();call validate_scalar_session_program(p,d);call check(d%code==0,'padded character parameter')
    p%symbols(1)%constant_value%s='bad';d=diagnostic_t()
    call validate_scalar_session_program(p,d);call check(d%code/=0,'character cache mismatch')
    print *,checks,' REPL values checks passed'
contains
    subroutine parse(source,prog)
        character(*),intent(in)::source
        type(program_t),intent(out)::prog
        d=diagnostic_t();call parse_subset(source//'end program p'//nl,prog,d)
        if(d%code==0)call verify_frontend(source//'end program p'//nl,prog,d)
        call check(d%code==0,'parse/front end')
    end subroutine
    subroutine check(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(.not.ok)then
            print *, 'FAIL ',label
            if(allocated(d%message))print *,d%message
            stop 1
        end if
    end subroutine
end program
