! SPDX-License-Identifier: MIT
program test_random_seed_empty
    use, intrinsic::iso_fortran_env,only:int64
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::seed_source='program p'//nl//'call random_seed()'//nl//'end program'
    character(*),parameter::nested_source='program p'//nl// &
        'real(8)::a(2),b(2),x'//nl//'real::s,t'//nl// &
        'call random_number(a)'//nl//'call reset()'//nl//'call random_number(b)'//nl// &
        'if(any(a/=b)) error stop 1'//nl//'x=draw()'//nl// &
        'if(x/=a(1)) error stop 2'//nl//'call random_number(x)'//nl// &
        'if(x/=a(2)) error stop 3'//nl//'call random_seed'//nl//'call random_number(s)'//nl// &
        'call random_seed()'//nl//'call random_number(t)'//nl//'if(s/=t) error stop 4'//nl// &
        'call random_seed()'//nl//'contains'//nl//'subroutine reset()'//nl// &
        'call deeper()'//nl//'end subroutine'//nl//'subroutine deeper()'//nl// &
        'call random_seed()'//nl//'end subroutine'//nl// &
        'real(8) function draw() result(r)'//nl//'call reset()'//nl// &
        'call random_number(r)'//nl//'end function'//nl//'end program'
    character(*),parameter::effect_source='program p'//nl//'real(8)::x'//nl//'x=draw()'//nl// &
        'contains'//nl//'real(8) function draw() result(r)'//nl//'call reset()'//nl//'r=0d0'//nl// &
        'end function'//nl//'subroutine reset()'//nl//'call random_seed()'//nl// &
        'end subroutine'//nl//'end program'
    type(program_t)::p
    type(diagnostic_t)::d
    integer(int64)::state
    integer::checks,j,k,stage,which,inst,caller,callee
    character(:),allocatable::source
    checks=0
    call compile(nested_source)
    do j=1,2
        state=104729_int64;d=diagnostic_t()
        call execute_program(p,d,random_state=state)
        call expect(d%code==0,'nested scalar, array, function and parenthesis-free reset execution')
        call expect(state==104729_int64,'nested reset updates shared stream')
    end do
    call compile(seed_source)
    state=17_int64
    call execute_program(p,d,random_state=state)
    call expect(d%code==0.and.state==104729_int64,'reset arbitrary valid execution-owned state')
    d=diagnostic_t();state=17_int64
    call execute_program(p,d,random_state=state,max_steps=0_int64)
    call expect(d%code==2.and.state==17_int64,'budget failure precedes reset')
    d=diagnostic_t();state=17_int64
    call execute_program(p,d,random_state=state,max_steps=1_int64)
    call expect(d%code==0.and.state==104729_int64,'reset costs one statement step')
    d=diagnostic_t();state=0_int64
    call execute_program(p,d,random_state=state)
    call expect(d%code==2.and.state==0_int64,'reset does not conceal an invalid execution state')
    ! Every unused operand must retain its canonical empty value, independently
    ! checked by the source adapter and executor before the stream is changed.
    do stage=1,2
        do which=1,16
            call parse_subset(seed_source,p,d)
            call expect(d%code==0,'mutation fixture parse')
            inst=0
            do k=1,p%nc
                if(p%code(k)%op==op_random_seed) inst=k
            end do
            call expect(inst>0,'seed opcode exists')
            select case(which)
            case(1);p%code(inst)%symbol=1
            case(2);p%code(inst)%a=1
            case(3);p%code(inst)%b=1
            case(4);p%code(inst)%c=1
            case(5);p%code(inst)%d=1
            case(6);p%code(inst)%target=1
            case(7);p%code(inst)%component=1
            case(8);p%code(inst)%generic_id=1
            case(9);p%code(inst)%third=1
            case(10);p%code(inst)%bound_type=1
            case(11);p%code(inst)%bound_binding=1
            case(12);allocate(p%code(inst)%items(0))
            case(13);p%code(inst)%format=''
            case(14);p%code(inst)%construct_name='unexpected'
            case(15);p%code(inst)%scope=1
            case(16);p%code(inst)%op=-1
            end select
            state=17_int64
            if(stage==1) then
                call verify_frontend(seed_source,p,d)
            else
                call execute_program(p,d,random_state=state)
            end if
            call expect(d%code==stage,'reject malformed seed metadata')
            call expect(state==17_int64,'malformed seed does not change stream')
        end do
    end do
    ! PURE and SIMPLE flags are checked on every stack entry, including an
    ! otherwise ordinary function's transitive call to a seeding subroutine.
    do stage=1,2
        do which=1,4
            call parse_subset(effect_source,p,d)
            call expect(d%code==0,'effect fixture parse')
            caller=0;callee=0
            do k=1,p%np
                if(p%procedures(k)%name=='draw') caller=k
                if(p%procedures(k)%name=='reset') callee=k
            end do
            call expect(caller>0.and.callee>0,'effect procedures present')
            select case(which)
            case(1);p%procedures(caller)%is_pure=.true.
            case(2);p%procedures(callee)%is_pure=.true.
            case(3);p%procedures(caller)%is_simple=.true.
            case(4);p%procedures(callee)%is_simple=.true.
            end select
            state=17_int64
            if(stage==1) then
                call verify_frontend(effect_source,p,d)
            else
                call execute_program(p,d,random_state=state)
            end if
            call expect(d%code==stage,'reject PURE/SIMPLE seed effect')
            call expect(state==17_int64,'forbidden seed effect does not change stream')
        end do
    end do
    do which=1,10
        select case(which)
        case(1);source='call random_seed(size=n)'
        case(2);source='call random_seed(put=a)'
        case(3);source='call random_seed(get=a)'
        case(4);source='call random_seed(n)'
        case(5);source='call random_seed(,)'
        case(6);source='call random_seed(x=1)'
        case(7);source='call random_seed(1,2)'
        case(8);source='call random_seed() extra'
        case(9);source='n=random_seed()'
        case(10);source='call random_seed('
        end select
        source='program p'//nl//'integer::n,a(2)'//nl//'print *,123'//nl//source//nl//'end program'
        call parse_subset(source,p,d)
        call expect(d%code==1,'reject nonempty or malformed intrinsic source before execution')
    end do
    do which=1,3
        select case(which)
        case(1);source='pure subroutine bad()'
        case(2);source='simple subroutine bad()'
        case(3);source='elemental subroutine bad()'
        end select
        source='program p'//nl//'contains'//nl//source//nl//'call random_seed()'//nl// &
            'end subroutine'//nl//'end program'
        call parse_subset(source,p,d)
        call expect(d%code==1,'source rejects PURE, SIMPLE and implicitly PURE ELEMENTAL reset')
    end do
    ! A reset evaluating a RANDOM_NUMBER destination is covered by the existing
    ! harvest transaction: an invalid destination restores its entry state.
    call compile('program p'//nl//'real(8)::a(2)'//nl//'call random_number(a(index():))'//nl// &
        'contains'//nl//'integer function index() result(i)'//nl//'call random_seed()'//nl// &
        'i=0'//nl//'end function'//nl//'end program')
    state=17_int64;call execute_program(p,d,random_state=state)
    call expect(d%code==2.and.state==17_int64,'failed harvest restores state before nested reset')
    ! An ordinary data name remains legal, but cannot be called as an intrinsic.
    call compile('program p'//nl//'integer::random_seed'//nl//'random_seed=3'//nl// &
        'if(random_seed/=3) error stop 1'//nl//'end program')
    call execute_program(p,d)
    call expect(d%code==0,'ordinary data spelling remains usable')
    call parse_subset('program p'//nl//'integer::random_seed'//nl//'call random_seed()'//nl//'end program',p,d)
    call expect(d%code==1,'data declaration shadows the intrinsic')
    ! Visible subroutines and module generics are ordinary user calls, even in
    ! PURE contexts; their calls must not reset the execution-owned stream.
    source='program p'//nl//'integer::x'//nl//'call random_seed(x)'//nl// &
        'if(x/=9) error stop 1'//nl//'contains'//nl// &
        'pure subroutine random_seed(x)'//nl//'integer,intent(out)::x'//nl//'x=9'//nl// &
        'end subroutine'//nl//'end program'
    call compile(source)
    state=17_int64;call execute_program(p,d,random_state=state)
    call expect(d%code==0.and.state==17_int64,'user subroutine shadow dispatch')
    ! A malicious relabeling of a user CALL must not pass source/IR validation.
    do k=1,p%nc
        if(p%code(k)%op/=op_call) cycle
        p%code(k)%op=op_random_seed;p%code(k)%symbol=0
        if(allocated(p%code(k)%items)) deallocate(p%code(k)%items)
        exit
    end do
    d=diagnostic_t();call verify_frontend(source,p,d)
    call expect(d%code==1,'adapter rejects intrinsic opcode substituted for declared subroutine')
    source='module m'//nl//'interface random_seed'//nl//'module procedure seed'//nl// &
        'end interface'//nl//'contains'//nl//'pure subroutine seed(x)'//nl// &
        'integer,intent(out)::x'//nl//'x=7'//nl//'end subroutine'//nl//'end module'//nl// &
        'program p'//nl//'use m'//nl//'integer::x'//nl//'call random_seed(x)'//nl// &
        'if(x/=7) error stop 1'//nl//'end program'
    call compile(source)
    state=17_int64;call execute_program(p,d,random_state=state)
    call expect(d%code==0.and.state==17_int64,'module generic shadow dispatch')
    source='program p'//nl//'integer::x'//nl//'call wrapper(x)'//nl// &
        'if(x/=5) error stop 1'//nl//'contains'//nl//'pure subroutine wrapper(x)'//nl// &
        'integer,intent(out)::x'//nl//'call random_seed(x)'//nl//'end subroutine'//nl// &
        'pure subroutine random_seed(x)'//nl//'integer,intent(out)::x'//nl//'x=5'//nl// &
        'end subroutine'//nl//'end program'
    call compile(source)
    state=17_int64;call execute_program(p,d,random_state=state)
    call expect(d%code==0.and.state==17_int64,'PURE caller can invoke PURE user shadow')
    source='program p'//nl//'integer::x'//nl//'x=random_seed()'//nl// &
        'if(x/=42) error stop 1'//nl//'contains'//nl// &
        'integer function random_seed() result(i)'//nl//'i=42'//nl//'end function'//nl//'end program'
    call compile(source)
    state=17_int64;call execute_program(p,d,random_state=state)
    call expect(d%code==0.and.state==17_int64,'user function shadow keeps expression semantics')
    source='program p'//nl//'integer::k'//nl//'k=kind(draw())'//nl// &
        'if(k/=8) error stop 1'//nl//'contains'//nl//'real(8) function draw() result(r)'//nl// &
        'call random_seed()'//nl//'r=0d0'//nl//'end function'//nl//'end program'
    call compile(source)
    state=17_int64;call execute_program(p,d,random_state=state)
    call expect(d%code==0.and.state==17_int64,'metadata-only KIND does not execute reset')
    ! Adapter checks source arguments independently of the trusted parser.
    call parse_subset('program p'//nl//'integer::n'//nl//'call random_seed()'//nl//'end program',p,d)
    call expect(d%code==0,'argument mismatch baseline')
    call verify_frontend('program p'//nl//'integer::n'//nl//'call random_seed(size=n)'//nl//'end program',p,d)
    call expect(d%code==1,'adapter rejects nonempty source actuals')
    print '(a,i0,a)','PASS: ',checks,' RANDOM_SEED empty-argument, shared-stream, metadata, effect and shadow checks'
contains
    subroutine compile(src)
        character(*),intent(in)::src
        call parse_subset(src,p,d)
        call expect(d%code==0,'source parse')
        call verify_frontend(src,p,d)
        call expect(d%code==0,'source adapter')
    end subroutine
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok) return
        print '(a)','FAIL: '//label
        if(allocated(d%message)) print '(a)',d%message
        error stop 1
    end subroutine
end program
