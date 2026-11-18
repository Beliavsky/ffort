! SPDX-License-Identifier: MIT
program test_repl_array_intrinsics
    use, intrinsic::iso_fortran_env,only:int64,real64
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime
    implicit none
    character(*),parameter::nl=new_line('a'),head='program p'//nl//'implicit none'//nl// &
        'integer :: a(-1:1),n,b(1)'//nl//'real(kind=8) :: r(3)'//nl
    character(:),allocatable::source
    type(program_t)::p,q,bad
    type(diagnostic_t)::d
    type(scalar_session_t)::session
    type(value_t)::v
    type(value_t),allocatable::values(:)
    logical,allocatable::flags(:)
    logical::defined
    integer(int64)::lower_bound
    integer::checks=0,j,k,root,frontier
    source=head//'a=[-1,2,-3]'//nl//'r=[1.0_8,4.0_8,9.0_8]'//nl// &
        'a=abs(a)'//nl//'r=sqrt(r)'//nl//'n=size(a,1)'//nl//'b=lbound(a)'//nl
    call parse(source,p)
    call execute_scalar_session(session,p,d);call check(d%code==0,'elemental/inquiry retained execution')
    call inspect_session_array(session,1,values,flags,lower_bound,d)
    call check(d%code==0.and.all(flags),'defined INTEGER array')
    call check(lower_bound==-1.and.all(values%i==[1_int64,2_int64,3_int64]),'ABS and bounds')
    call inspect_session_array(session,4,values,flags,lower_bound,d)
    call check(d%code==0.and.all(flags),'defined REAL array')
    do j=1,3
        call check(abs(values(j)%r-real(j,real64))<1.0e-12_real64,'SQRT values')
    end do
    call inspect_scalar_session(session,2,v,defined,d)
    call check(d%code==0.and.defined.and.v%i==3,'SIZE result')
    call inspect_session_array(session,3,values,flags,lower_bound,d)
    call check(d%code==0.and.all(flags).and.values(1)%i==-1,'LBOUND vector')
    frontier=scalar_session_frontier(session)
    call parse(source//'print *,sum(abs(a))'//nl,q)
    do j=1,3
        call execute_scalar_session(session,q,d,commit=.false.)
        call check(d%code==0.and.scalar_session_frontier(session)==frontier,'repeated query no replay')
    end do
    root=0
    do j=1,p%ne
        if(p%expressions(j)%kind==ex_call.and.p%expressions(j)%op=='sqrt')root=j
    end do
    do k=1,12
        bad=p
        select case(k)
        case(1);bad%expressions(root)%rank=0
        case(2);bad%expressions(root)%extent=2
        case(3);bad%expressions(root)%real_kind=4
        case(4);bad%expressions(root)%typ=ty_integer
        case(5);bad%expressions(root)%args=[root]
        case(6);bad%expressions(root)%args=[0]
        case(7);bad%expressions(root)%args=[1,1]
        case(8);bad%expressions(root)%intrinsic_mask=1
        case(9);bad%expressions(root)%dims=[3_int64,1_int64,1_int64]
        case(10);bad%expressions(root)%symbol=1
        case(11);bad%expressions(root)%left=1
        case(12);bad%expressions(root)%op='tan'
        end select
        d=diagnostic_t();call validate_scalar_session_program(bad,d)
        call check(d%code/=0,'elemental metadata mutation refused')
        call check(.not.scalar_session_tainted(session),'admission rejection leaves healthy session')
    end do
    call reset_scalar_session(session)
    source=head//'n=size(r)'//nl//'b=ubound(a)'//nl
    call parse(source,p);call execute_scalar_session(session,p,d)
    call check(d%code==0,'undefined array inquiries')
    call inspect_session_array(session,1,values,flags,lower_bound,d)
    call check(d%code==0.and..not.any(flags),'inquiry preserves undefined flags')
    call inspect_scalar_session(session,2,v,defined,d)
    call check(d%code==0.and.defined.and.v%i==3,'undefined SIZE value')
    print *, 'retained array intrinsic author checks:',checks
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
end program
