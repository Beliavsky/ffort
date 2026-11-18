! SPDX-License-Identifier: MIT
program test_repl_loop_control
    use, intrinsic::iso_fortran_env,only:int64
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime
    implicit none
    character(*),parameter::nl=new_line('a'),head='program p'//nl//'implicit none'//nl// &
        'integer :: i,j,k,s,a(2)'//nl
    character(:),allocatable::source
    type(program_t)::p,q,bad
    type(diagnostic_t)::d
    type(scalar_session_t)::session
    type(value_t)::v
    logical::defined
    integer::checks=0,j,k,first,inner,transfer,back,frontier,levels,last
    source=head//'s=0'//nl//'i=0'//nl//'outer: do while(i<3)'//nl//'i=i+1'//nl// &
        'inner: do j=1,3'//nl//'if(j==2) cycle inner'//nl//'s=s+1'//nl// &
        'if(i==2) exit outer'//nl//'END DO inner'//nl//'ENDDO outer'//nl// &
        'j=9'//nl//'s=0'//nl//'counted: do i=1,3'//nl//'do'//nl// &
        's=s+1'//nl//'cycle counted'//nl//'enddo'//nl//'enddo counted'//nl// &
        'k=0'//nl//'do'//nl//'k=k+1'//nl//'if(k==2) exit'//nl//'enddo'//nl// &
        'a=2'//nl//'do while(sum(a)>0)'//nl//'a=a-1'//nl//'enddo'//nl
    call parse(source,p)
    call execute_scalar_session(session,p,d);call check(d%code==0,'mixed structured loops execute')
    call value(1,4_int64);call value(2,9_int64);call value(3,2_int64);call value(4,3_int64)
    frontier=scalar_session_frontier(session)
    call parse(source//'print *,s'//nl,q)
    do j=1,2
        call execute_scalar_session(session,q,d,commit=.false.)
        call check(d%code==0.and.scalar_session_frontier(session)==frontier,'query no replay')
    end do
    call value(4,3_int64)
    first=0;inner=0;transfer=0
    do j=1,p%nc
        if(p%code(j)%op==op_do.and.first==0)then
            first=j
        else if(p%code(j)%op==op_do.and.inner==0)then
            inner=j
        end if
        if(p%code(j)%op==op_exit.and.transfer==0)transfer=j
    end do
    back=p%code(first)%target-1
    call check(first>0.and.inner>first.and.transfer>inner,'fixture control sites')
    do k=1,18
        bad=p
        select case(k)
        case(1);bad%code(first)%symbol=1
        case(2);bad%code(first)%b=1
        case(3);bad%code(first)%a=0
        case(4);bad%code(first)%a=bad%code(inner)%a
        case(5);bad%code(first)%d=3
        case(6);bad%code(first)%construct_name='Outer'
        case(7);bad%code(first)%construct_name='bad name'
        case(8);bad%code(back)%construct_name='other'
        case(9);bad%code(back)%d=1
        case(10);bad%code(back)%symbol=1
        case(11);bad%code(transfer)%construct_name=''
        case(12);bad%code(transfer)%construct_name='missing'
        case(13);bad%code(transfer)%a=inner
        case(14);bad%code(transfer)%target=bad%nc+1
        case(15);bad%code(transfer)%d=1
        case(16);bad%code(transfer)%items=[1]
        case(17:18)
            do j=1,bad%nc
                if(bad%code(j)%construct_name/='outer')cycle
                if(k==17)bad%code(j)%construct_name='do'
                if(k==18)bad%code(j)%construct_name='abs'
            end do
        end select
        call reject(bad)
    end do
    ! Scope-wide duplicate names must reject even when loops are disjoint.
    bad=p
    do j=first+1,p%nc
        if(bad%code(j)%op/=op_do.or.bad%code(j)%construct_name/='counted')cycle
        bad%code(j)%construct_name='outer'
        bad%code(bad%code(j)%target-1)%construct_name='outer'
        exit
    end do
    call reject(bad)
    ! Actual parser spelling is normalized; string content is not involved.
    call reset_scalar_session(session)
    call parse(head//'k=0'//nl//'MiXeD: DO'//nl//'k=k+1'//nl// &
        'if(k==2) EXIT mIxEd'//nl//'EnDdO MIXED'//nl,p)
    call execute_scalar_session(session,p,d);call check(d%code==0,'case-insensitive named syntax')
    call value(3,2_int64)
    call reset_scalar_session(session)
    call parse(head//'k=0'//nl//'do while(k<3)'//nl//'k=k+1'//nl//'cycle'//nl//'k=99'//nl//'enddo'//nl,p)
    call execute_scalar_session(session,p,d);call check(d%code==0,'WHILE CYCLE retests')
    call value(3,3_int64)
    call reset_scalar_session(session)
    call parse(head//'k=0'//nl//'LOOP: DO WHILE(k<2)'//nl//'k=k+1'//nl// &
        'if(k==2) EXIT LOOP'//nl//'CYCLE LOOP'//nl//'END DO LOOP'//nl,p)
    call execute_scalar_session(session,p,d);call check(d%code==0,'uppercase WHILE header')
    call value(3,2_int64)
    call failure(head//'do'//nl//'enddo'//nl,20_int64)
    call failure(head//'do while(.true.)'//nl//'enddo'//nl,20_int64)
    call failure(head//'do while(i>0)'//nl//'enddo'//nl,1000_int64)
    ! Direct IR nesting boundary; no execution of intentionally infinite loops.
    do levels=64,65
        call parse('program p'//nl,p)
        deallocate(p%code);allocate(p%code(2*levels));p%nc=2*levels
        do j=1,levels
            last=2*levels-j+1
            p%code(j)=instruction_t(op=op_do,d=1,target=last+1)
            p%code(last)=instruction_t(op=op_next,d=1,a=j,target=j+1)
        end do
        d=diagnostic_t();call validate_scalar_session_program(p,d)
        call check((d%code==0).eqv.(levels==64),'depth64/65 admission boundary')
    end do
    ! Maximum4000 instructions allows2000 disjoint named pairs; no extra low name cap.
    call parse('program p'//nl,p)
    deallocate(p%code);allocate(p%code(max_instructions));p%nc=max_instructions
    do j=1,max_instructions,2
        p%code(j)=instruction_t(op=op_do,d=1,target=j+2)
        write(p%code(j)%construct_name,'(a,i4.4)')'loop',j
        p%code(j+1)=instruction_t(op=op_next,d=1,a=j,target=j+1,construct_name=p%code(j)%construct_name)
    end do
    d=diagnostic_t();call validate_scalar_session_program(p,d)
    call check(d%code==0,'maximum named loop pair population')
    p%code(max_instructions-1)%construct_name=p%code(1)%construct_name
    p%code(max_instructions)%construct_name=p%code(1)%construct_name
    d=diagnostic_t();call validate_scalar_session_program(p,d)
    call check(d%code/=0,'distant duplicate name rejected')
    print *, 'retained full loop checks: ',checks
contains
    subroutine parse(text,prog)
        character(*),intent(in)::text
        type(program_t),intent(out)::prog
        d=diagnostic_t();call parse_subset(text//'end program'//nl,prog,d)
        call check(d%code==0,'fixture parse')
        call verify_frontend(text//'end program'//nl,prog,d)
        call check(d%code==0,'fixture frontend')
    end subroutine
    subroutine value(index,expected)
        integer,intent(in)::index
        integer(int64),intent(in)::expected
        d=diagnostic_t();call inspect_scalar_session(session,index,v,defined,d)
        call check(d%code==0.and.defined.and.v%i==expected,'retained value')
    end subroutine
    subroutine reject(prog)
        type(program_t),intent(in)::prog
        integer::old
        old=scalar_session_frontier(session)
        d=diagnostic_t();call validate_scalar_session_program(prog,d)
        call check(d%code/=0,'forged loop rejected before effects')
        d=diagnostic_t();call execute_scalar_session(session,prog,d)
        call check(d%code/=0.and..not.scalar_session_tainted(session),'rejection not tainted')
        call check(scalar_session_frontier(session)==old,'frontier unchanged')
    end subroutine
    subroutine failure(text,steps)
        character(*),intent(in)::text
        integer(int64),intent(in)::steps
        call reset_scalar_session(session);call parse(text,p)
        call execute_scalar_session(session,p,d,max_steps=steps)
        call check(d%code/=0.and.scalar_session_tainted(session),'runtime failure taints')
        d=diagnostic_t();call execute_scalar_session(session,p,d)
        call check(d%code/=0,'no failed suffix retry')
    end subroutine
    subroutine check(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        if(.not.ok)then
            print *, 'FAIL ',label,' case ',k
            if(allocated(d%message))print *,d%message
            stop 1
        end if
        checks=checks+1
    end subroutine
end program
