! SPDX-License-Identifier: MIT
program test_cshift
    use,intrinsic::iso_fortran_env,only:int64
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program,evaluate_constant_array
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        'integer::a(2,3),b(2,3),s(2),d'//nl//'a=reshape([1,2,3,4,5,6],[2,3])'//nl// &
        's=[1,-1]'//nl//'d=2'//nl//'b=cshift(a,shift=s,dim=d)'//nl// &
        'if(any(b/=reshape([3,6,5,2,1,4],[2,3]))) error stop 1'//nl//'end program'
    type(program_t)::p
    type(diagnostic_t)::diag
    type(value_t),allocatable::values(:)
    integer::stage,which,e,a,s,d,j,k,checks
    integer(int64)::state,wanted
    checks=0
    do stage=1,2
        do which=1,25
            call baseline()
            select case(which)
            case(2);deallocate(p%expressions(e)%args)
            case(3);p%expressions(e)%args=[a]
            case(4);p%expressions(e)%args=[a,s,d,d]
            case(5);p%expressions(e)%args(1)=0
            case(6);p%expressions(e)%args(2)=e
            case(7);p%expressions(e)%args(3)=p%ne+1
            case(8);p%expressions(e)%intrinsic_mask=3
            case(9);p%expressions(e)%typ=ty_real
            case(10);p%expressions(e)%real_kind=8
            case(11);p%expressions(e)%rank=1
            case(12);p%expressions(e)%extent=5
            case(13);p%expressions(e)%dims=[3_int64,2_int64,1_int64]
            case(14);p%expressions(a)%rank=3
            case(15);p%expressions(a)%typ=ty_derived_base+1
            case(16);p%expressions(s)%typ=ty_real
            case(17);p%expressions(s)%real_kind=16
            case(18);p%expressions(s)%rank=2
            case(19);p%expressions(d)%typ=ty_real
            case(20);p%expressions(d)%rank=1
            case(21);p%expressions(d)%real_kind=16
            case(22);p%expressions(a)%real_kind=16
            case(23);p%expressions(e)%args(2)=d
            case(24);p%expressions(s)%extent=1
            case(25);p%expressions(a)%extent=5
            end select
            if(stage==1) then
                call verify_frontend(source,p,diag)
            else
                call execute_program(p,diag,max_steps=5000_int64)
            end if
            ! Case23 changes array SHIFT to a legitimate scalar. The adapter
            ! must reject source disagreement, but the standalone IR is valid.
            if(stage==2.and.which==23) then
                call expect(diag%code==2,'valid altered scalar reaches assertion')
                call expect(index(diag%message,'ERROR STOP: 1')>0,'valid scalar reached expected value assertion')
            else
                call expect((which==1.and.diag%code==0).or.(which/=1.and.diag%code==stage),'mutation status')
                if(which/=1.and.allocated(diag%message)) &
                    call expect(index(diag%message,'ERROR STOP')==0,'mutation guard before user assertion')
            end if
            if(which/=1) call expect(allocated(diag%message),'diagnostic present')
        end do
    end do
    call parse_subset('program p'//nl//'integer,parameter::v(4)=cshift([1,2,3,4],-1)'//nl// &
        'if(any(v/=[4,1,2,3])) error stop 1'//nl//'end program',p,diag)
    call expect(diag%code==0,'constant CSHIFT parse')
    call verify_frontend('program p'//nl//'integer,parameter::v(4)=cshift([1,2,3,4],-1)'//nl// &
        'if(any(v/=[4,1,2,3])) error stop 1'//nl//'end program',p,diag)
    call expect(diag%code==0,'constant CSHIFT adapter')
    call execute_program(p,diag)
    call expect(diag%code==0,'constant CSHIFT execution')
    ! Unevaluated KIND must validate structural CSHIFT metadata without reading
    ! uninitialized ARRAY, SHIFT, DIM or calling an impure source function.
    call parse_subset('program p'//nl//'real(8)::a(3)'//nl//'integer::s,d,k'//nl// &
        'k=kind(cshift(a,s,d))'//nl//'if(k/=8) error stop 1'//nl// &
        'k=kind(cshift(draw(),s,d))'//nl//'contains'//nl//'function draw() result(r)'//nl// &
        'real(8)::r(3)'//nl//'call random_number(r)'//nl//'end function'//nl//'end program',p,diag)
    call expect(diag%code==0,'KIND parse')
    state=104729_int64;call execute_program(p,diag,random_state=state)
    call expect(diag%code==0,'KIND execution')
    call expect(state==104729_int64,'KIND did not draw')
    ! One source array function and one scalar shift call per occurrence.
    call parse_subset('program p'//nl//'real(8)::a(4)'//nl//'a=cshift(draw(),amount())'//nl// &
        'contains'//nl//'function draw() result(r)'//nl//'real(8)::r(4)'//nl// &
        'call random_number(r)'//nl//'end function'//nl// &
        'integer function amount() result(n)'//nl//'real(8)::x'//nl// &
        'call random_number(x)'//nl//'n=1'//nl//'end function'//nl//'end program',p,diag)
    call expect(diag%code==0,'effects parse')
    wanted=104729_int64
    do j=1,5
        wanted=modulo(wanted*16807_int64,2147483647_int64)
    end do
    state=104729_int64;call execute_program(p,diag,random_state=state)
    call expect(diag%code==0,'effects run')
    call expect(state==wanted,'exactly five random draws')
    ! Failure followed by a fresh execution of immutable IR cannot retain cache.
    call baseline()
    call execute_program(p,diag,max_steps=4_int64)
    call expect(diag%code==2,'work limit')
    do j=1,2
        diag=diagnostic_t();call execute_program(p,diag)
        call expect(diag%code==0,'cache reset after budget failure')
    end do
    call parse_subset('module m'//nl//'contains'//nl// &
        'function cshift(a,n) result(r)'//nl//'integer,intent(in)::a(:),n'//nl// &
        'integer::r(size(a))'//nl//'r=a+n'//nl//'end function'//nl//'end module'//nl// &
        'program p'//nl//'use m'//nl//'integer::a(3),b(3)'//nl//'a=[1,2,3]'//nl// &
        'b=cshift(a,1)'//nl//'end program',p,diag)
    call expect(diag%code==0,'source-defined CSHIFT parse')
    do j=1,p%ne
        if(p%expressions(j)%kind/=ex_user_call) cycle
        a=p%expressions(j)%args(1)
        p%expressions(j)%kind=ex_call;p%expressions(j)%op='cshift';p%expressions(j)%symbol=0
        p%expressions(j)%intrinsic_mask=3
        p%expressions(j)%extent=p%expressions(a)%extent;p%expressions(j)%dims=p%expressions(a)%dims
    end do
    call verify_frontend('module m'//nl//'contains'//nl// &
        'function cshift(a,n) result(r)'//nl//'integer,intent(in)::a(:),n'//nl// &
        'integer::r(size(a))'//nl//'r=a+n'//nl//'end function'//nl//'end module'//nl// &
        'program p'//nl//'use m'//nl//'integer::a(3),b(3)'//nl//'a=[1,2,3]'//nl// &
        'b=cshift(a,1)'//nl//'end program',p,diag)
    call expect(diag%code==1,'forged intrinsic source identity rejected')
    print '(a,i0,a)','PASS: ',checks,' CSHIFT adapter/runtime, KIND, effects and reset checks'
contains
    subroutine baseline()
        call parse_subset(source,p,diag)
        if(diag%code/=0) then
            print *,diag%message
            error stop 'CSHIFT fixture parse'
        end if
        e=0
        do k=1,p%ne
            if(p%expressions(k)%kind/=ex_call.or.p%expressions(k)%op/='cshift') cycle
            e=k
        end do
        if(e==0) error stop 'CSHIFT fixture binding'
        a=p%expressions(e)%args(1);s=p%expressions(e)%args(2);d=p%expressions(e)%args(3)
    end subroutine
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok) return
        print *,stage,which,label,diag%code
        if(allocated(diag%message)) print *,diag%message
        error stop 'CSHIFT check failed'
    end subroutine
end program
