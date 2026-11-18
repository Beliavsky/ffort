! SPDX-License-Identifier: MIT
! Independent cross-feature adapter mutants and parser-free public-IR graphs.
program test_release037_composition
    use,intrinsic::iso_fortran_env,only:int64,real64,real32,output_unit,error_unit
    use,intrinsic::ieee_arithmetic,only:ieee_is_negative,ieee_value,ieee_quiet_nan,ieee_positive_inf
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program,evaluate_constant
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        'real(8)::a(3,2),b(3,2)'//nl//'integer::e(3,2)'//nl// &
        'a=reshape([-8d0,0.5d0,3d0,16d0,-0.25d0,0d0],[3,2])'//nl// &
        'e=exponent(a([3,1,3],:))'//nl// &
        'b=set_exponent(fraction(a([3,1,3],:)),e)'//nl// &
        'if(count(b==a([3,1,3],:))/=6)error stop 1'//nl// &
        'if(count(spacing(b)>0d0)/=6)error stop 2'//nl// &
        'if(count(nearest(b,1d0)>b)/=6)error stop 3'//nl// &
        'if(any(isnan(b)))error stop 4'//nl// &
        'if(iachar("A",8)/=65_8)error stop 5'//nl// &
        'write(*,''("composed:",3(1x,i0))'')sum(e),count(b>0d0),kind(iachar("A",8))'//nl// &
        'end program'
    character(12),parameter::names(7)=[character(12):: &
        'fraction','exponent','set_exponent','iachar','spacing','nearest','isnan']
    character(*),parameter::rng_decls='program p'//nl//'implicit none'//nl// &
        'real(8)::a(3),b(0),x'//nl//'integer::i'//nl
    character(*),parameter::rng_functions='contains'//nl// &
        'function draw() result(x)'//nl//'real(8)::x'//nl// &
        'call random_number(x)'//nl//'end function'//nl// &
        'function vec(n) result(x)'//nl//'integer,intent(in)::n'//nl// &
        'real(8)::x(n)'//nl//'call random_number(x)'//nl//'end function'//nl//'end program'
    type(program_t)::p,q,r,control
    type(diagnostic_t)::d
    type(value_t)::v
    integer::checks,j,k,e,which,stage,status,family,root,kind_root,proc
    integer(int64)::state,wanted,first_state,second_state
    character(300)::line
    character(:),allocatable::actual,reference,rng_source,control_source,body,direct_body
    checks=0;which=0;stage=0;family=0
    close(output_unit)
    open(unit=output_unit,status='scratch',action='readwrite',form='formatted')
    call parse_subset(source,p,d);call expect(d%code==0,'composition parse')
    call verify_frontend(source,p,d);call expect(d%code==0,'composition adapter')
    do j=1,3
        d=diagnostic_t();call clear_output();call execute_program(p,d)
        call expect(d%code==0,'repeat composition runtime')
        call read_output(actual)
        call expect(actual=='composed: 13 3 8'//nl,'exact repeated composition record')
    end do
    do family=1,7
        e=0
        do j=1,p%ne
            if(p%expressions(j)%op==trim(names(family)).and.e==0)e=j
        end do
        call expect(e>0,'intrinsic retained in composed program')
        do which=1,10
            q=p
            select case(which)
            case(1);q%expressions(e)%real_kind=16
            case(2);q%expressions(e)%typ=ty_character
            case(3);q%expressions(e)%args(1)=0
            case(4);q%expressions(e)%args(1)=q%ne+1
            case(5);q%expressions(e)%args(1)=e
            case(6);q%expressions(e)%intrinsic_mask=-1
            case(7);q%expressions(e)%args=[integer::]
            case(8);q%expressions(e)%rank=4
            case(9);q%expressions(e)%dims(3)=17_int64
            case(10);deallocate(q%expressions(e)%args)
            end select
            call reject_both(q,source,'composed intrinsic mutation')
        end do
    end do
    ! Correct source-free scalar roots precede independent child/result mutations.
    do family=1,7
        do which=0,11
            call direct_scalar(family)
            select case(which)
            case(1);q%expressions(root)%real_kind=16
            case(2);q%expressions(root)%typ=ty_character
            case(3);q%expressions(root)%args(1)=0
            case(4);q%expressions(root)%args(1)=q%ne+1
            case(5);q%expressions(root)%args(1)=root
            case(6);q%expressions(root)%intrinsic_mask=1
            case(7);q%expressions(root)%args=[integer::]
            case(8);q%expressions(root)%rank=1
            case(9);q%expressions(1)%real_kind=16
            case(10);q%expressions(1)%value%real_kind=16
            case(11);q%expressions(root)%extent=1_int64
            end select
            d=diagnostic_t();call evaluate_constant(q,root,v,d)
            call expect((d%code==0).eqv.(which==0),'source-free intrinsic validation')
            if(which==0)call check_scalar_value(family)
            d=diagnostic_t();call evaluate_constant(q,kind_root,v,d)
            call expect((d%code==0).eqv.(which==0),'KIND cannot conceal malformed child')
            if(which==0)call expect(v%i==q%expressions(root)%real_kind,'KIND result is exact')
        end do
    end do
    ! Valid nested roots are evaluated repeatedly without parser certification.
    do which=0,7
        call direct_scalar(1)
        q%expressions(2)=expr_t(kind=ex_literal,typ=ty_integer,real_kind=8, &
            value=value_t(tag=ty_integer,real_kind=8,i=4_int64))
        q%expressions(4)=expr_t(kind=ex_call,typ=ty_real,real_kind=8,op='set_exponent',args=[3,2])
        q%expressions(5)=expr_t(kind=ex_call,typ=ty_logical,op='isnan',args=[4])
        q%expressions(6)=expr_t(kind=ex_call,typ=ty_integer,op='kind',args=[5]);q%ne=6
        select case(which)
        case(1);q%expressions(3)%real_kind=4
        case(2);q%expressions(4)%args=[3]
        case(3);q%expressions(5)%real_kind=8
        case(4);q%expressions(4)%args(2)=5
        case(5);q%expressions(3)%intrinsic_mask=1
        case(6);q%expressions(1)%dims(1)=1
        case(7);q%expressions(5)%extent=1
        end select
        do j=1,2
            d=diagnostic_t();call evaluate_constant(q,5,v,d)
            call expect((d%code==0).eqv.(which==0),'source-free nested finite predicate')
            if(which==0)call expect(.not.v%l.and.v%tag==ty_logical,'nested predicate exact false')
            d=diagnostic_t();call evaluate_constant(q,6,v,d)
            call expect((d%code==0).eqv.(which==0),'nested KIND validates descendants')
        end do
    end do
    ! Direct finite policy is not an accidental NaN/Infinity-support promise.
    do family=1,7
        if(family==4)cycle
        do which=1,2
            call direct_scalar(family)
            if(which==1)q%expressions(1)%value%r=ieee_value(0d0,ieee_quiet_nan)
            if(which==2)q%expressions(1)%value%r=ieee_value(0d0,ieee_positive_inf)
            call evaluate_constant(q,root,v,d)
            call expect(d%code/=0,'forged nonfinite REAL rejected')
        end do
    end do
    ! Signed-zero and least subnormal values checked through IEEE sign bits.
    do family=1,2
        call direct_scalar(3)
        q%expressions(1)%value%r=-0d0
        q%expressions(2)%value%i=huge(0_int64)
        if(family==2)q%expressions(2)%value%i=-huge(0_int64)
        call evaluate_constant(q,root,v,d)
        call expect(d%code==0.and.v%r==0d0,'zero survives wide exponent')
        call expect(ieee_is_negative(v%r),'SET_EXPONENT negative zero bit')
    end do
    call direct_scalar(6)
    call evaluate_constant(q,root,v,d)
    call expect(d%code==0.and.v%r==-tiny(0d0)*epsilon(0d0),'negative least subnormal exact')
    call expect(ieee_is_negative(v%r),'NEAREST subnormal negative sign')
    ! RNG result values/state are compared only within the documented candidate
    ! generator, never against GNU's unrelated stream. Direct CALL is the control.
    do family=1,11
        select case(family)
        case(1)
            body='a=fraction(vec(3))'//nl
            direct_body='call random_number(a)'//nl//'a=fraction(a)'//nl
        case(2)
            body='a=nearest(draw(),[1d0,1d0,1d0])'//nl
            direct_body='call random_number(x)'//nl//'a=nearest(x,[1d0,1d0,1d0])'//nl
        case(3)
            body='do i=1,3'//nl//'a(i)=draw()'//nl//'end do'//nl
            direct_body='do i=1,3'//nl//'call random_number(a(i))'//nl//'end do'//nl
        case(4)
            body='x=draw()+draw()'//nl//'a=x'//nl
            direct_body='call random_number(a(1:2))'//nl//'x=a(1)+a(2)'//nl//'a=x'//nl
        case(5)
            body='b=vec(0)'//nl//'a=spacing(draw())+[0d0,0d0,0d0]'//nl
            direct_body='call random_number(b)'//nl//'call random_number(x)'//nl// &
                'a=spacing(x)+[0d0,0d0,0d0]'//nl
        case(6)
            body='i=kind(isnan(draw()))'//nl//'a=set_exponent(draw(),[0,1,2])'//nl
            direct_body='i=4'//nl//'call random_number(x)'//nl//'a=set_exponent(x,[0,1,2])'//nl
        case(7)
            body='a=vec(3)'//nl//'a=set_exponent(fraction(a),exponent(a))'//nl
            direct_body='call random_number(a)'//nl//'a=set_exponent(fraction(a),exponent(a))'//nl
        case(8)
            body='i=size(vec(3))'//nl//'a=dble(i)'//nl
            direct_body='call random_number(a)'//nl//'i=size(a)'//nl//'a=dble(i)'//nl
        case(9)
            body='i=kind(vec(3))'//nl//'a=draw()'//nl
            direct_body='i=8'//nl//'call random_number(x)'//nl//'a=x'//nl
        case(10)
            body='b=draw()'//nl//'a=draw()'//nl
            direct_body='call random_number(x)'//nl//'b=x'//nl//'call random_number(x)'//nl//'a=x'//nl
        case(11)
            body='b=b+draw()'//nl//'a=draw()'//nl
            direct_body='b=b+0d0'//nl//'call random_number(x)'//nl//'a=x'//nl
        end select
        rng_source=rng_decls//body//'write(*,''(3(es24.16,1x))'')a'//nl//rng_functions
        control_source=rng_decls//direct_body//'write(*,''(3(es24.16,1x))'')a'//nl//'end program'
        call parse_subset(rng_source,r,d);call expect(d%code==0,'RNG composition parse')
        call verify_frontend(rng_source,r,d);call expect(d%code==0,'RNG composition adapter')
        call parse_subset(control_source,control,d);call expect(d%code==0,'direct RNG control parse')
        call verify_frontend(control_source,control,d);call expect(d%code==0,'direct RNG control adapter')
        first_state=104729_int64;call run_capture(control,first_state,reference)
        do j=1,3
            state=104729_int64;call run_capture(r,state,actual)
            call expect(state==first_state,'same-seed direct/function stream state')
            call expect(actual==reference,'same-seed direct/function output values')
        end do
        ! Omitting caller-owned state resets each top-level execution.
        do j=1,2
            d=diagnostic_t();call clear_output();call execute_program(r,d)
            call expect(d%code==0,'default seed execution')
            call read_output(actual)
            call expect(actual==reference,'default seed reset reproducibility')
        end do
        ! Caller-owned state continues, rather than resetting inside functions.
        second_state=first_state;call run_capture(control,second_state,reference)
        state=first_state;call run_capture(r,state,actual)
        call expect(state==second_state.and.actual==reference,'continued RNG stream')
        if(family/=7)cycle
        proc=0
        do k=1,r%np
            if(r%procedures(k)%name=='vec')proc=k
        end do
        call expect(proc>0,'ordinary RNG procedure retained')
        do which=1,4
            q=r
            select case(which)
            case(1);q%procedures(proc)%is_pure=.true.
            case(2);q%procedures(proc)%is_simple=.true.;q%procedures(proc)%is_pure=.false.
            case(3);q%procedures(proc)%result_symbol=0
            case(4)
                do k=1,q%nc
                    if(q%code(k)%op==op_random_number.and.q%code(k)%scope==proc)q%code(k)%a=0
                end do
            end select
            call reject_both(q,rng_source,'RNG function effect/result mutation')
            state=104729_int64;d=diagnostic_t();call clear_output()
            call execute_program(q,d,random_state=state)
            call expect(d%code==2.and.state==104729_int64,'invalid RNG IR has no state effect')
        end do
    end do
    ! A failing print stages no partial record; an earlier successful draw is
    ! retained. A failing RANDOM_NUMBER harvest rolls back only its own nested
    ! draws, not a previous completed statement.
    do family=1,2
        if(family==1)then
            rng_source=rng_decls//'write(*,''(a)'')"before"'//nl// &
                'print *,draw(),fraction(x)'//nl//rng_functions
        else
            rng_source=rng_decls//'x=draw()'//nl//'write(*,''(a)'')"before"'//nl// &
                'call random_number(a(index():))'//nl// &
                'contains'//nl//'function draw() result(y)'//nl//'real(8)::y'//nl// &
                'call random_number(y)'//nl//'end function'//nl// &
                'function index() result(i)'//nl//'integer::i'//nl//'real(8)::y'//nl// &
                'call random_number(y)'//nl//'i=0'//nl//'end function'//nl//'end program'
        end if
        call parse_subset(rng_source,r,d);call expect(d%code==0,'RNG failure source parse')
        call verify_frontend(rng_source,r,d);call expect(d%code==0,'RNG failure source adapter')
        state=104729_int64;d=diagnostic_t();call clear_output()
        call execute_program(r,d,random_state=state)
        call expect(d%code==2,'RNG failure reports runtime diagnostic')
        call expect(state==modulo(104729_int64*16807_int64,2147483647_int64),'RNG operation rollback boundary')
        call read_output(actual)
        call expect(actual=='before'//nl,'RNG failure record is atomic')
    end do
    close(output_unit)
    write(error_unit,'(a,i0,a)')'PASS: release 0.37 independent composition: ',checks,' checks'
contains
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok)return
        write(error_unit,*)label,' family=',family,' mutation=',which,' stage=',stage,' code=',d%code
        if(allocated(d%message))write(error_unit,*)d%message
        error stop 1
    end subroutine
    subroutine clear_output()
        rewind(output_unit);endfile(output_unit);rewind(output_unit)
    end subroutine
    subroutine read_output(value)
        character(:),allocatable,intent(out)::value
        value='';rewind(output_unit)
        do
            read(output_unit,'(a)',iostat=status)line
            if(status<0)exit
            call expect(status==0,'read captured record')
            value=value//trim(line)//nl
        end do
    end subroutine
    subroutine run_capture(program,state,value)
        type(program_t),intent(in)::program
        integer(int64),intent(inout)::state
        character(:),allocatable,intent(out)::value
        d=diagnostic_t();call clear_output()
        call execute_program(program,d,random_state=state)
        call expect(d%code==0,'RNG composed execution')
        call read_output(value)
    end subroutine
    subroutine reject_both(program,text,label)
        type(program_t),intent(in)::program
        character(*),intent(in)::text,label
        do stage=1,2
            d=diagnostic_t();call clear_output()
            if(stage==1)then
                call verify_frontend(text,program,d)
            else
                call execute_program(program,d,max_steps=10000_int64)
            end if
            call expect(d%code==stage,label)
            call expect(d%stop_status==0,'guard is not user STOP')
            call expect(allocated(d%message),'guard diagnostic allocated')
            if(allocated(d%message))call expect(len_trim(d%message)>0,'guard diagnostic nonempty')
            call read_output(actual)
            call expect(actual=='','malformed composition cannot emit output')
        end do
    end subroutine
    subroutine direct_scalar(n)
        integer,intent(in)::n
        q=program_t();d=diagnostic_t()
        allocate(q%symbols(0),q%expressions(6),q%code(0));q%ne=4
        q%expressions(1)=expr_t(kind=ex_literal,typ=ty_real,real_kind=8, &
            value=value_t(tag=ty_real,real_kind=8,r=3d0))
        q%expressions(2)=expr_t(kind=ex_literal,typ=ty_integer,real_kind=8, &
            value=value_t(tag=ty_integer,real_kind=8,i=4_int64))
        q%expressions(3)=expr_t(kind=ex_call,typ=ty_real,real_kind=8,op=trim(names(n)),args=[1])
        select case(n)
        case(2);q%expressions(3)%typ=ty_integer;q%expressions(3)%real_kind=4
        case(3);q%expressions(3)%args=[1,2]
        case(4)
            q%expressions(1)=expr_t(kind=ex_literal,typ=ty_character,character_len=1, &
                value=value_t(tag=ty_character,s='A'))
            q%expressions(2)%value%i=8_int64
            q%expressions(3)%typ=ty_integer;q%expressions(3)%args=[1,2]
        case(5);q%expressions(1)%value%r=1d0
        case(6)
            q%expressions(1)%value%r=0d0
            q%expressions(2)=expr_t(kind=ex_literal,typ=ty_real,real_kind=4, &
                value=value_t(tag=ty_real,real_kind=4,r=-1d0))
            q%expressions(3)%args=[1,2]
        case(7);q%expressions(3)%typ=ty_logical;q%expressions(3)%real_kind=4
        end select
        q%expressions(4)=expr_t(kind=ex_call,typ=ty_integer,op='kind',args=[3])
        root=3;kind_root=4
    end subroutine
    subroutine check_scalar_value(n)
        integer,intent(in)::n
        select case(n)
        case(1);call expect(v%tag==ty_real.and.v%r==0.75d0,'FRACTION exact')
        case(2);call expect(v%tag==ty_integer.and.v%i==2,'EXPONENT exact')
        case(3);call expect(v%tag==ty_real.and.v%r==12d0,'SET_EXPONENT exact')
        case(4);call expect(v%tag==ty_integer.and.v%real_kind==8.and.v%i==65,'IACHAR ASCII exact')
        case(5);call expect(v%tag==ty_real.and.v%r==epsilon(0d0),'SPACING exact')
        case(6);call expect(v%tag==ty_real.and.v%r==-tiny(0d0)*epsilon(0d0),'NEAREST least subnormal exact')
        case(7);call expect(v%tag==ty_logical.and..not.v%l,'finite ISNAN false')
        end select
    end subroutine
end program
