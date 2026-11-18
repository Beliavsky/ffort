! SPDX-License-Identifier: MIT
! Direct-runtime negative tests: each mutation starts with a freshly parsed,
! successfully executed honest POINTER program. The changed IR is then passed
! straight to execute_program, with no parser or frontend revalidation.
program test_pointer_runtime_metadata
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_runtime, only: execute_program
    implicit none
    character(*), parameter :: nl=new_line('a')
    character(*), parameter :: association_source='program main'//nl// &
        'integer,target::a(2)'//nl//'integer,pointer::p(:)'//nl// &
        'p=>a'//nl//'if(.not.associated(p)) error stop 1'//nl//'end'
    character(*), parameter :: null_source='program main'//nl// &
        'integer,pointer::p(:)'//nl//'p=>null()'//nl// &
        'if(associated(p)) error stop 1'//nl//'end'
    character(*), parameter :: nullify_source='program main'//nl// &
        'integer,pointer::p(:)'//nl//'nullify(p)'//nl// &
        'if(associated(p)) error stop 1'//nl//'end'
    character(*), parameter :: escape_source='module m'//nl//'contains'//nl// &
        'subroutine bind(x,p)'//nl//'integer,target,intent(inout)::x(:)'//nl// &
        'integer,pointer,intent(out)::p(:)'//nl//'integer,target::local(2)'//nl// &
        'local=7'//nl//'p=>x'//nl//'end subroutine'//nl//'end module'//nl// &
        'program main'//nl//'use m'//nl//'integer,target::a(2)'//nl// &
        'integer,pointer::p(:)'//nl//'a=3'//nl//'call bind(a,p)'//nl// &
        'if(.not.associated(p)) error stop 1'//nl// &
        'p(1)=9'//nl//'if(a(1)/=9) error stop 2'//nl//'end'
    type(program_t) :: p
    type(diagnostic_t) :: d
    integer :: which,s,t,c,e,a,tests
    character(100) :: label

    tests=0
    do which=1,32
        call baseline(association_source)
        s=symbol_named('p',0)
        select case(which)
        case(1); p%symbols(s)%rank=0; label='scalar POINTER declaration'
        case(2); p%symbols(s)%rank=2; label='rank-two POINTER declaration'
        case(3); p%symbols(s)%typ=ty_logical; label='LOGICAL POINTER declaration'
        case(4); p%symbols(s)%typ=ty_character; label='CHARACTER POINTER declaration'
        case(5); p%symbols(s)%real_kind=16; label='unsupported POINTER kind'
        case(6); p%symbols(s)%scope=-1; label='module POINTER declaration'
        case(7); p%symbols(s)%is_allocatable=.true.; label='ALLOCATABLE POINTER declaration'
        case(8); p%symbols(s)%is_target=.true.; label='TARGET POINTER declaration'
        case(9); p%symbols(s)%is_parameter=.true.; label='PARAMETER POINTER declaration'
        case(10); p%symbols(s)%is_automatic=.true.; label='automatic POINTER declaration'
        case(11); p%symbols(s)%assumed_shape=.true.; label='assumed-shape POINTER declaration'
        case(12); p%symbols(s)%is_class=.true.; label='polymorphic POINTER declaration'
        case(13); p%symbols(s)%initializer_expr=1; label='initialized POINTER declaration'
        case(14); p%symbols(s)%lower_bound=0; label='fixed POINTER lower bound'
        case(15); p%symbols(s)%upper_bound=2; label='fixed POINTER upper bound'
        case(16); p%symbols(s)%lower_expr=1; label='POINTER lower-bound expression'
        case(17); p%symbols(s)%upper_expr=1; label='POINTER upper-bound expression'
        case(18); p%symbols(s)%lower_expr2=1; label='POINTER second lower-bound expression'
        case(19); p%symbols(s)%upper_expr2=1; label='POINTER second upper-bound expression'
        case(20); p%symbols(s)%lower_expr3=1; label='POINTER third lower-bound expression'
        case(21); p%symbols(s)%upper_expr3=1; label='POINTER third upper-bound expression'
        case(22); p%symbols(s)%scope=p%np+1; label='out-of-range POINTER procedure scope'
        case(23); p%symbols(s)%is_intrinsic=.true.; label='INTRINSIC POINTER declaration'
        case(24); p%symbols(s)%deferred_character=.true.; label='numeric deferred-character POINTER'
        case(25); p%symbols(s)%character_len=2; label='numeric POINTER character length'
        case(26); p%symbols(s)%length_expr=1; label='numeric POINTER length expression'
        case(27); p%symbols(s)%lower_bound2=0; label='POINTER inactive second lower bound'
        case(28); p%symbols(s)%upper_bound2=0; label='POINTER inactive second upper bound'
        case(29); p%symbols(s)%lower_bound3=0; label='POINTER inactive third lower bound'
        case(30); p%symbols(s)%upper_bound3=0; label='POINTER inactive third upper bound'
        case(31); p%symbols(s)%parameter_ready=.true.; label='POINTER cached PARAMETER state'
        case(32)
            allocate(p%symbols(s)%constant_values(0)); label='POINTER constant array payload'
        end select
        call rejected(label)
    end do

    ! Attribute consistency is validated before any instructions execute.
    do which=1,7
        call baseline(association_source)
        s=symbol_named('p',0)
        select case(which)
        case(1)
            p%symbols(s)%is_dummy=.true.; p%symbols(s)%dummy_intent=1
            label='main-program POINTER marked as dummy'
        case(2); p%symbols(s)%dummy_intent=-1; label='local POINTER negative INTENT'
        case(3); p%symbols(s)%dummy_intent=1; label='local POINTER INTENT(IN)'
        case(4); p%symbols(s)%dummy_intent=2; label='local POINTER INTENT(OUT)'
        case(5); p%symbols(s)%dummy_intent=3; label='local POINTER INTENT(INOUT)'
        case(6); p%symbols(s)%dummy_intent=4; label='local POINTER invalid INTENT'
        case(7); p%symbols(s)%is_optional=.true.; label='local POINTER OPTIONAL attribute'
        end select
        if(which==1) then
            call rejected(label,'invalid POINTER dummy declaration')
        else
            call rejected(label,'invalid local POINTER declaration')
        end if
    end do
    do which=1,5
        call baseline(escape_source)
        s=symbol_named('p',1)
        select case(which)
        case(1); p%symbols(s)%dummy_intent=0; label='POINTER dummy missing explicit INTENT'
        case(2); p%symbols(s)%dummy_intent=-1; label='POINTER dummy negative INTENT'
        case(3); p%symbols(s)%dummy_intent=4; label='POINTER dummy invalid INTENT'
        case(4); p%symbols(s)%is_dummy=.false.; label='procedure local POINTER retains dummy INTENT'
        case(5)
            p%symbols(s)%is_dummy=.false.; p%symbols(s)%dummy_intent=0
            p%symbols(s)%is_optional=.true.; label='procedure local POINTER marked OPTIONAL'
        end select
        if(which<=3) then
            call rejected(label,'invalid POINTER dummy declaration')
        else
            call rejected(label,'invalid local POINTER declaration')
        end if
    end do

    do which=1,15
        call baseline(association_source)
        c=instruction_with(op_pointer_assign)
        call corrupt_instruction(c,which)
        write(label,'(a,i0)') 'POINTER association instruction operand ',which
        call rejected(label)
    end do
    do which=1,16
        call baseline(nullify_source)
        c=instruction_with(op_nullify)
        if(which==16) then
            p%code(c)%a=1
        else
            call corrupt_instruction(c,which)
        end if
        write(label,'(a,i0)') 'NULLIFY instruction operand ',which
        call rejected(label)
    end do

    do which=1,22
        call baseline(association_source)
        c=instruction_with(op_pointer_assign); e=p%code(c)%a
        select case(which)
        case(1); p%expressions(e)%typ=ty_real; label='source expression forged type'
        case(2); p%expressions(e)%real_kind=8; label='source expression forged numeric kind'
        case(3)
            p%expressions(e)%rank=0; p%expressions(e)%extent=0
            label='source expression forged scalar rank'
        case(4)
            p%expressions(e)%rank=2; p%expressions(e)%dims=[2,1,1]
            label='source expression forged matrix rank'
        case(5); p%expressions(e)%parenthesized=.true.; label='parenthesized target expression'
        case(6); p%expressions(e)%kind=ex_binary; label='nondesignator target expression'
        case(7); p%expressions(e)%symbol=0; label='zero target expression symbol'
        case(8); p%expressions(e)%symbol=p%ns+1; label='out-of-range target expression symbol'
        case(9); p%expressions(e)%scope=p%np+1; label='target expression outside active frame'
        case(10); p%expressions(e)%extent=1; label='wrong whole-target cached extent'
        case(11); p%expressions(e)%dims=[2,1,1]; label='spurious rank-one target dimensions'
        case(12); p%expressions(e)%extent=-1; label='dynamic extent on fixed target expression'
        case(13); p%expressions(e)%third=1; label='third element index on whole target'
        case(14); p%expressions(e)%left3=1; label='third section index on whole target'
        case(15); p%code(c)%a=p%ne+1; label='out-of-range association expression'
        case(16); p%expressions(e)%left=1; label='whole target unexpected first subscript'
        case(17); p%expressions(e)%right=1; label='whole target unexpected first upper bound'
        case(18); p%expressions(e)%stride=1; label='whole target unexpected first stride'
        case(19); p%expressions(e)%left2=1; label='whole target unexpected second subscript'
        case(20); p%expressions(e)%right2=1; label='whole target unexpected second upper bound'
        case(21); p%expressions(e)%stride2=1; label='whole target unexpected second stride'
        case(22); p%expressions(e)%args=[e]; label='whole target unexpected argument payload'
        end select
        call rejected(label)
    end do

    ! No target data are read by this baseline, so declaration/source metadata
    ! mismatches reach association validation rather than an earlier assignment.
    do which=1,7
        call baseline(association_source)
        t=symbol_named('a',0)
        select case(which)
        case(1); p%symbols(t)%is_target=.false.; label='target missing TARGET attribute'
        case(2); p%symbols(t)%typ=ty_real; label='source type differs from target declaration'
        case(3); p%symbols(t)%real_kind=8; label='source kind differs from target declaration'
        case(4); p%symbols(t)%rank=0; label='source rank differs from scalar target declaration'
        case(5); p%symbols(t)%rank=2; label='whole rank-two target disguised as rank one'
        case(6); p%symbols(t)%rank=3; label='unsupported rank-three target storage'
        case(7); p%symbols(t)%is_automatic=.true.; label='automatic target storage'
        end select
        call rejected(label)
    end do

    do which=1,11
        call baseline(null_source)
        e=call_named('null')
        select case(which)
        case(1); deallocate(p%expressions(e)%args); label='NULL missing operand storage'
        case(2); p%expressions(e)%args=[e]; label='NULL unexpected argument'
        case(3); p%expressions(e)%typ=ty_integer; label='NULL forged result type'
        case(4); p%expressions(e)%rank=1; label='NULL forged result rank'
        case(5); p%expressions(e)%real_kind=8; label='NULL forged result kind'
        case(6); p%expressions(e)%extent=1; label='NULL forged extent'
        case(7); p%expressions(e)%dims=[1,0,0]; label='NULL forged dimensions'
        case(8); p%expressions(e)%parenthesized=.true.; label='NULL parenthesized descriptor'
        case(9); p%expressions(e)%scope=p%np+1; label='NULL outside active frame'
        case(10); p%expressions(e)%third=1; label='NULL unexpected element index'
        case(11); p%expressions(e)%left3=1; label='NULL unexpected section index'
        end select
        call rejected(label)
    end do

    do which=1,17
        call baseline(null_source)
        e=call_named('null')
        call corrupt_call(e,which)
        write(label,'(a,i0)') 'NULL unexpected expression payload ',which
        call rejected(label)
        call baseline(null_source)
        e=call_named('associated')
        call corrupt_call(e,which)
        write(label,'(a,i0)') 'ASSOCIATED unexpected expression payload ',which
        call rejected(label)
    end do

    do which=1,10
        call baseline(null_source)
        e=call_named('associated'); a=p%expressions(e)%args(1)
        select case(which)
        case(1); deallocate(p%expressions(e)%args); label='ASSOCIATED missing arguments'
        case(2); p%expressions(e)%args=[integer::]; label='ASSOCIATED zero arguments'
        case(3); p%expressions(e)%args=[a,a,a]; label='ASSOCIATED three arguments'
        case(4); p%expressions(e)%typ=ty_integer; label='ASSOCIATED forged result type'
        case(5); p%expressions(e)%rank=1; label='ASSOCIATED forged result rank'
        case(6); p%expressions(e)%real_kind=8; label='ASSOCIATED forged result kind'
        case(7); p%expressions(e)%extent=1; label='ASSOCIATED forged result extent'
        case(8); p%expressions(e)%dims=[1,0,0]; label='ASSOCIATED forged result dimensions'
        case(9); p%expressions(e)%args(1)=0; label='ASSOCIATED invalid zero operand'
        case(10); p%expressions(e)%args(1)=p%ne+1; label='ASSOCIATED operand out of range'
        end select
        call rejected(label)
    end do
    do which=1,11
        call baseline(null_source)
        e=call_named('associated'); a=p%expressions(e)%args(1)
        select case(which)
        case(1); p%expressions(a)%kind=ex_section; label='ASSOCIATED section operand'
        case(2); p%expressions(a)%parenthesized=.true.; label='ASSOCIATED parenthesized operand'
        case(3); p%expressions(a)%typ=ty_real; label='ASSOCIATED operand forged type'
        case(4); p%expressions(a)%real_kind=8; label='ASSOCIATED operand forged kind'
        case(5)
            p%expressions(a)%rank=0; p%expressions(a)%extent=0
            label='ASSOCIATED operand forged scalar rank'
        case(6); p%expressions(a)%rank=2; label='ASSOCIATED operand forged matrix rank'
        case(7); p%expressions(a)%extent=0; label='ASSOCIATED operand forged fixed extent'
        case(8); p%expressions(a)%dims=[1,0,0]; label='ASSOCIATED operand forged dimensions'
        case(9); p%expressions(a)%symbol=0; label='ASSOCIATED operand missing binding'
        case(10); p%expressions(a)%scope=p%np+1; label='ASSOCIATED operand outside active frame'
        case(11); p%expressions(a)%symbol=p%ns+1; label='ASSOCIATED operand binding out of range'
        end select
        call rejected(label)
    end do

    call baseline(association_source)
    c=instruction_with(op_pointer_assign)
    p%code(c)%op=op_nullify; p%code(c)%a=0
    e=call_named('associated'); a=p%expressions(e)%args(1)
    p%expressions(a)%symbol=symbol_named('a',0)
    p%expressions(a)%extent=2
    call rejected('ASSOCIATED ordinary TARGET operand','whole pointer variable')

    ! Removing the initializing descriptor operation, while preserving an honest
    ! parsed expression, must not turn undefined status into a false result.
    call baseline(null_source)
    c=instruction_with(op_pointer_assign)
    p%entry_pc=c+1
    call rejected('ASSOCIATED undefined association status','status is undefined')

    call baseline('program main'//nl//'integer,target::a(2)'//nl// &
        'integer,pointer::p(:),q(:)'//nl//'p=>a'//nl//'q=>p'//nl// &
        'if(.not.associated(q)) error stop 1'//nl//'end')
    s=symbol_named('q',0)
    do c=1,p%nc
        if(p%code(c)%op==op_pointer_assign.and.p%code(c)%symbol==s) exit
    end do
    if(c>p%nc) error stop 'pointer copy baseline association missing'
    e=p%code(c)%a; p%expressions(e)%kind=ex_section
    call rejected('pointer-to-pointer section target')

    call baseline(escape_source)
    p%procedures(1)%is_elemental=.true.
    call rejected('POINTER declaration in ELEMENTAL subroutine')

    call baseline(escape_source)
    p%procedures(1)%is_subroutine=.false.
    call rejected('POINTER declaration in function')

    call baseline(escape_source)
    c=instruction_with(op_pointer_assign); e=p%code(c)%a
    t=symbol_named('local',1)
    p%expressions(e)%symbol=t; p%expressions(e)%extent=2
    call rejected('procedure-local target escapes frame','lifetime has expired')

    call baseline(escape_source)
    t=symbol_named('a',0); p%symbols(t)%is_target=.false.
    call rejected('TARGET dummy actual lacks caller TARGET backing','shareable caller backing')

    print '(a,i0,a)','PASS: ',tests,' direct-runtime POINTER metadata/lifetime rejections'
contains
    subroutine baseline(source)
        character(*), intent(in) :: source
        d=diagnostic_t()
        call parse_subset(source,p,d)
        if(d%code/=0) then
            if(allocated(d%message)) print *,d%message
            error stop 'honest POINTER baseline did not parse'
        end if
        call execute_program(p,d)
        if(d%code/=0) then
            if(allocated(d%message)) print *,d%message
            error stop 'honest POINTER baseline did not execute'
        end if
    end subroutine

    subroutine rejected(name,fragment)
        character(*), intent(in) :: name
        character(*), intent(in), optional :: fragment
        d=diagnostic_t()
        call execute_program(p,d)
        if(d%code/=2) then
            print *,trim(name),': expected runtime code 2, got ',d%code
            if(allocated(d%message)) print *,d%message
            error stop 'forged POINTER metadata accepted or wrong diagnostic class'
        end if
        if(.not.allocated(d%message)) error stop 'runtime rejection missing diagnostic'
        if(present(fragment)) then
            if(index(d%message,fragment)==0) then
                print *,trim(name),': ',d%message
                error stop 'POINTER rejection came from wrong runtime guard'
            end if
        end if
        tests=tests+1
    end subroutine

    integer function symbol_named(name,scope) result(s)
        character(*), intent(in) :: name
        integer, intent(in) :: scope
        integer :: i
        s=0
        do i=1,p%ns
            if(p%symbols(i)%name/=name.or.p%symbols(i)%scope/=scope) cycle
            s=i; return
        end do
        error stop 'required baseline symbol missing'
    end function

    integer function instruction_with(op) result(c)
        integer, intent(in) :: op
        integer :: i
        c=0
        do i=1,p%nc
            if(p%code(i)%op/=op) cycle
            c=i; return
        end do
        error stop 'required baseline instruction missing'
    end function

    integer function call_named(name) result(e)
        character(*), intent(in) :: name
        integer :: i
        e=0
        do i=1,p%ne
            if(p%expressions(i)%kind/=ex_call.or.p%expressions(i)%op/=name) cycle
            e=i; return
        end do
        error stop 'required baseline call expression missing'
    end function

    subroutine corrupt_call(e,which)
        integer, intent(in) :: e,which
        select case(which)
        case(1); p%expressions(e)%left=1
        case(2); p%expressions(e)%right=1
        case(3); p%expressions(e)%stride=1
        case(4); p%expressions(e)%left2=1
        case(5); p%expressions(e)%right2=1
        case(6); p%expressions(e)%stride2=1
        case(7); p%expressions(e)%third=1
        case(8); p%expressions(e)%left3=1
        case(9); p%expressions(e)%right3=1
        case(10); p%expressions(e)%stride3=1
        case(11); p%expressions(e)%symbol=1
        case(12); p%expressions(e)%generic_id=1
        case(13); p%expressions(e)%bound_type=1
        case(14); p%expressions(e)%bound_binding=1
        case(15); p%expressions(e)%intrinsic_mask=1
        case(16); p%expressions(e)%length_expr=1
        case(17); p%expressions(e)%character_len=1
        end select
    end subroutine

    subroutine corrupt_instruction(c,which)
        integer, intent(in) :: c,which
        select case(which)
        case(1); p%code(c)%b=1
        case(2); p%code(c)%c=1
        case(3); p%code(c)%d=1
        case(4); p%code(c)%third=1
        case(5); p%code(c)%component=1
        case(6); p%code(c)%target=1
        case(7); p%code(c)%generic_id=1
        case(8); p%code(c)%bound_type=1
        case(9); p%code(c)%bound_binding=1
        case(10); p%code(c)%items=[1]
        case(11); p%code(c)%format='*'
        case(12); p%code(c)%construct_name='forged'
        case(13); p%code(c)%symbol=0
        case(14); p%code(c)%symbol=p%ns+1
        case(15); p%symbols(p%code(c)%symbol)%is_pointer=.false.
        end select
    end subroutine
end program
