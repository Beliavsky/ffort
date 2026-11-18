! SPDX-License-Identifier: MIT
program test_random_functions
    use, intrinsic::iso_fortran_env,only:int64
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::stream_source='program p'//nl//'implicit none'//nl// &
        'real(8)::a(4),b(4),c(0),d(2,2,2),s'//nl//'integer::i,k'//nl// &
        'a=draw()'//nl//'if(any(a/=a(1))) error stop 1'//nl// &
        'b=draw()+draw()'//nl//'if(any(b/=b(1))) error stop 2'//nl// &
        'do i=1,2'//nl//'s=draw()'//nl//'end do'//nl//'c=empty()'//nl// &
        'd=cube()'//nl//'s=recursive_draw(3)'//nl//'k=kind(draw())'//nl// &
        'if(k/=8) error stop 3'//nl//'call sink(draw())'//nl//'contains'//nl// &
        'real(8) function draw() result(r)'//nl//'call random_number(r)'//nl//'end function'//nl// &
        'function empty() result(r)'//nl//'real(8)::r(0)'//nl//'call random_number(r)'//nl//'end function'//nl// &
        'function cube() result(r)'//nl//'real(8)::r(2,2,2)'//nl//'call random_number(r)'//nl//'end function'//nl// &
        'recursive function recursive_draw(n) result(r)'//nl//'integer,intent(in)::n'//nl//'real(8)::r'//nl// &
        'call random_number(r)'//nl//'if(n>0) r=r+recursive_draw(n-1)'//nl//'end function'//nl// &
        'subroutine sink(x)'//nl//'real(8),intent(in)::x'//nl//'end subroutine'//nl//'end program'
    character(*),parameter::mutation_source='module m'//nl//'contains'//nl// &
        'real(8) function draw() result(r)'//nl//'call helper(r)'//nl//'end function'//nl// &
        'subroutine helper(x)'//nl//'real(8),intent(out)::x'//nl//'call random_number(x)'//nl// &
        'end subroutine'//nl//'end module'//nl//'program p'//nl//'use m'//nl//'real(8)::x'//nl// &
        'x=draw()'//nl//'end program'
    type(program_t)::p
    type(diagnostic_t)::d
    integer::checks,j,which,stage,caller,callee,target,harvest,inst,call_expr
    integer(int64)::state,wanted
    checks=0
    call parse_subset(stream_source,p,d)
    call expect(d%code==0,'stream parse')
    call verify_frontend(stream_source,p,d)
    call expect(d%code==0,'stream adapter')
    wanted=104729_int64
    do j=1,18
        wanted=modulo(16807_int64*wanted,2147483647_int64)
    end do
    do j=1,2
        state=104729_int64;d=diagnostic_t()
        call execute_program(p,d,random_state=state)
        call expect(d%code==0,'stream run')
        call expect(state==wanted,'18 draws: scalar broadcast, occurrences, loop, rank three, recursion, KIND')
    end do
    ! Source/IR agreement and runtime independently reject corrupted effect,
    ! harvest, and call metadata; rejection is before any random draw.
    do stage=1,2
        do which=1,18
            call baseline()
            select case(which)
            case(2);p%procedures(caller)%is_pure=.true.
            case(3);p%procedures(callee)%is_pure=.true.
            case(4);p%procedures(caller)%is_simple=.true.
            case(5);p%procedures(callee)%is_simple=.true.
            case(6);p%expressions(harvest)%parenthesized=.true.
            case(7);p%expressions(harvest)%typ=ty_integer
            case(8);p%expressions(harvest)%real_kind=4
            case(9);p%expressions(harvest)%rank=1
            case(10);p%expressions(harvest)%symbol=0
            case(11);p%code(inst)%a=0
            case(12);p%symbols(target)%dummy_intent=1
            case(13);p%symbols(target)%is_parameter=.true.
            case(14);p%expressions(call_expr)%symbol=p%np+1
            case(15);p%expressions(call_expr)%real_kind=4
            case(16);p%procedures(caller)%result_symbol=0
            case(17)
                p%code(inst)%op=op_print;p%code(inst)%items=[harvest]
            case(18)
                p%code(inst)%op=op_write_defined;p%code(inst)%items=[harvest]
            end select
            state=104729_int64
            if(stage==1) then
                call verify_frontend(mutation_source,p,d)
            else
                call execute_program(p,d,random_state=state,max_steps=1000_int64)
            end if
            call expect((which==1.and.d%code==0).or.(which/=1.and.d%code==stage),'mutation status')
            if(stage==2.and.which/=1) call expect(state==104729_int64,'mutation advanced random state')
            if(which/=1) then
                call expect(allocated(d%message),'mutation diagnostic')
                call expect(d%stop_status==0,'mutation did not reach user error stop')
            end if
        end do
    end do
    ! A failed harvest (including draws evaluating its destination) restores the
    ! shared stream. This does not promise transaction rollback for whole functions.
    call parse_subset('program p'//nl//'real(8)::x(3)'//nl// &
        'call random_number(x(index():))'//nl//'contains'//nl// &
        'integer function index() result(r)'//nl//'real(8)::v'//nl// &
        'call random_number(v)'//nl//'r=0'//nl//'end function'//nl//'end program',p,d)
    call expect(d%code==0,'failed destination parse')
    state=104729_int64
    call execute_program(p,d,random_state=state)
    call expect(d%code==2,'failed destination rejected')
    call expect(state==104729_int64,'failed destination state rollback')
    call parse_subset('program p'//nl//'real(8)::x(1000)'//nl//'x=draw()'//nl//'contains'//nl// &
        'function draw() result(r)'//nl//'real(8)::r(1000)'//nl// &
        'call random_number(r)'//nl//'end function'//nl//'end program',p,d)
    call expect(d%code==0,'budget parse')
    state=104729_int64
    call execute_program(p,d,random_state=state,max_steps=40_int64)
    call expect(d%code==2,'draw budget enforced')
    call expect(state==104729_int64,'failed draw budget preserves state')
    ! Default fresh root state repeats, even after the same immutable IR failed.
    call parse_subset('program p'//nl//'real(8)::x'//nl//'x=draw()'//nl// &
        'if(x/=1760180303d0/2147483647d0) error stop 1'//nl//'contains'//nl// &
        'real(8) function draw() result(r)'//nl//'call random_number(r)'//nl//'end function'//nl//'end program',p,d)
    call expect(d%code==0,'reset parse')
    call execute_program(p,d,max_steps=1_int64)
    call expect(d%code==2,'reset prerequisite budget failure')
    do j=1,2
        d=diagnostic_t();call execute_program(p,d)
        call expect(d%code==0,'default stream resets per execution')
    end do
    print '(a,i0,a)','PASS: ',checks,' ordinary function RNG stream, effect, adapter and runtime checks'
contains
    subroutine baseline()
        integer::q
        call parse_subset(mutation_source,p,d)
        if(d%code/=0) error stop 'mutation fixture parse'
        caller=0;callee=0;inst=0;call_expr=0
        do q=1,p%np
            if(p%procedures(q)%name=='draw') caller=q
            if(p%procedures(q)%name=='helper') callee=q
        end do
        do q=1,p%nc
            if(p%code(q)%op==op_random_number) inst=q
        end do
        do q=1,p%ne
            if(p%expressions(q)%kind==ex_user_call) call_expr=q
        end do
        if(min(caller,callee,inst,call_expr)==0) error stop 'mutation fixture binding'
        target=p%code(inst)%symbol;harvest=p%code(inst)%a
    end subroutine
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok) return
        print *,label,stage,which,d%code
        if(allocated(d%message)) print *,d%message
        error stop 'ordinary function RNG check failed'
    end subroutine
end program
