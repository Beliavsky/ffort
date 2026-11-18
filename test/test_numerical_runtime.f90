! SPDX-License-Identifier: MIT
program test_numerical_runtime
    use, intrinsic :: iso_fortran_env, only: int64, real32, real64
    use fi_ir
    use fi_runtime, only: execute_program, evaluate_constant, validate_print_format
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    type(value_t)::v
    integer::i

    ! Kind-aware evaluation must retain REAL64 precision while preserving the
    ! earlier default REAL32 rounding contract after every operation.
    call numeric_fixture(8)
    call evaluate_constant(p,5,v,d)
    call expect(d%code==0.and.abs(v%r-((1.0_real64+1.0e-12_real64)-1.0_real64))<1.0e-25_real64, &
                'REAL64 arithmetic precision')
    call numeric_fixture(4)
    call evaluate_constant(p,5,v,d)
    call expect(d%code==0.and.v%r==0.0_real64,'REAL32 operation rounding')
    call numeric_fixture(8)
    p%expressions(1)%typ=ty_integer; p%expressions(1)%value%tag=ty_integer
    p%expressions(1)%value%i=16777217_int64
    call evaluate_constant(p,1,v,d,ty_real,8)
    call expect(d%code==0.and.v%real_kind==8.and.v%r==16777217.0_real64,'REAL64 constant conversion')
    d=diagnostic_t()
    call evaluate_constant(p,1,v,d,ty_real,4)
    call expect(d%code==0.and.v%real_kind==4.and.v%r==16777216.0_real64,'REAL32 constant conversion')
    do i=1,7
        call numeric_fixture(8)
        p%expressions(2)%value%r=2.0_real64
        p%expressions(3)=expr_t(kind=ex_call,typ=ty_real,real_kind=8,args=[2])
        select case(i)
        case(1); p%expressions(3)%op='sqrt'
        case(2); p%expressions(3)%op='log'
        case(3); p%expressions(3)%op='exp'
        case(4); p%expressions(3)%op='erfc'
        case(5); p%expressions(3)%op='sqrt'; p%expressions(2)%value%r=-1.0_real64
        case(6); p%expressions(3)%op='log'; p%expressions(2)%value%r=0.0_real64
        case(7); p%expressions(3)%op='exp'; p%expressions(2)%value%r=1000.0_real64
        end select
        call evaluate_constant(p,3,v,d)
        if(i<=4) then
            call expect(d%code==0.and.v%real_kind==8,'REAL64 intrinsic kind')
            select case(i)
            case(1); call expect(abs(v%r-sqrt(2.0_real64))<1.0e-15_real64,'SQRT value')
            case(2); call expect(abs(v%r-log(2.0_real64))<1.0e-15_real64,'LOG value')
            case(3); call expect(abs(v%r-exp(2.0_real64))<1.0e-15_real64,'EXP value')
            case(4); call expect(abs(v%r-erfc(2.0_real64))<1.0e-15_real64,'ERFC value')
            end select
        else
            call expect(d%code==2,'intrinsic domain/overflow rejection')
        end if
    end do

    do i=1,11
        call call_fixture()
        select case(i)
        case(2); p%code(3)%items=[integer::]
        case(3); p%expressions(1)%value%tag=ty_integer
        case(4); p%expressions(1)%value%real_kind=8
        case(5); p%code(1)%op=op_assign; p%code(1)%symbol=1; p%code(1)%a=2
        case(6); p%code(1)%scope=0
        case(7); p%procedures(1)%is_subroutine=.false.
        case(8); p%code(1)%op=op_call; p%code(1)%symbol=1; p%code(1)%items=[2]
        case(9); p%procedures(1)%args=[2]
        case(10); p%code(3)%symbol=2
        case(11); p%code(1)%op=op_error_stop; p%code(1)%a=0
        end select
        call execute_program(p,d)
        call expect((d%code==0).eqv.(i==1),'CALL/RETURN runtime invariant')
    end do
    call call_fixture()
    call execute_program(p,d,max_steps=1_int64)
    call expect(d%code==2,'shared CALL budget')

    call check_format('(a)',[ty_character],.true.)
    call check_format('(a,f16.10)',[ty_character,ty_real],.true.)
    call check_format('(a,es12.4)',[ty_character,ty_real],.true.)
    call check_format('(2i5,3x,l2)',[ty_integer,ty_integer,ty_logical],.true.)
    call check_format('(a4,e12.4,g16.8)',[ty_character,ty_real,ty_real],.true.)
    call check_format('(a)',[ty_real],.false.)
    call check_format('(a,a)',[ty_character],.true.)
    call check_format('(a)',[ty_character,ty_character],.false.)
    call check_format('(a,)',[ty_character],.false.)
    call check_format('(a.)',[ty_character],.false.)
    call check_format('(i5.)',[ty_integer],.false.)
    call check_format('(f16)',[ty_real],.false.)
    call check_format('(f0.4)',[ty_real],.true.)
    call check_format('(f999999999999.4)',[ty_real],.false.)
    call check_format('(65537x)',[integer::],.false.)
    call check_format('(2(a))',[ty_character,ty_character],.true.)
    call check_format('(a/)',[ty_character],.false.)
    call check_format('(es12.4e3)',[ty_real],.false.)
    call check_format('()',[integer::],.false.)

    ! An assumed-length CHARACTER dummy retains the actual string, and only a
    ! subroutine frame may perform I/O. The record is checked by the suite log.
    call call_fixture()
    p%symbols(1)%typ=ty_character
    p%expressions(1)%typ=ty_character; p%expressions(1)%value%tag=ty_character
    p%expressions(1)%value%s='CHARACTER subroutine runtime passed.'
    p%expressions(2)%typ=ty_character
    p%code(1)%op=op_print; p%code(1)%items=[2]; p%code(1)%format='(a)'
    p%procedures(1)%last=1
    call execute_program(p,d)
    call expect(d%code==0,'CHARACTER dummy and formatted output')
    d=diagnostic_t(); p%procedures(1)%is_pure=.true.
    call execute_program(p,d)
    call expect(d%code==2,'PURE subroutine I/O rejected')
    print '(a)','PASS: kind-aware arithmetic, four intrinsics, CALL/RETURN, budget and 19 format checks'
contains
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        if(ok) return
        print '(a)','FAILED: '//label
        if(allocated(d%message)) print '(a)',d%message
        error stop 1
    end subroutine
    subroutine empty_fixture()
        p=program_t(); d=diagnostic_t()
        allocate(p%symbols(2),p%expressions(5),p%code(3),p%procedures(1))
    end subroutine
    subroutine numeric_fixture(rk)
        integer,intent(in)::rk
        call empty_fixture()
        p%ne=5
        p%expressions(1)=expr_t(kind=ex_literal,typ=ty_real,real_kind=rk)
        p%expressions(1)%value=value_t(tag=ty_real,real_kind=rk,r=1.0_real64)
        p%expressions(2)=expr_t(kind=ex_literal,typ=ty_real,real_kind=rk)
        p%expressions(2)%value=value_t(tag=ty_real,real_kind=rk,r=1.0e-12_real64)
        p%expressions(3)=expr_t(kind=ex_binary,typ=ty_real,real_kind=rk,left=1,right=2,op='+')
        p%expressions(4)=p%expressions(1)
        p%expressions(5)=expr_t(kind=ex_binary,typ=ty_real,real_kind=rk,left=3,right=4,op='-')
    end subroutine
    subroutine call_fixture()
        call empty_fixture()
        p%ns=1; p%np=1; p%ne=2; p%nc=3; p%entry_pc=3
        p%procedures(1)=procedure_t(name='sub',is_subroutine=.true.,first=1,last=2,args=[1])
        p%symbols(1)=symbol_t(name='x',typ=ty_real,is_dummy=.true.,scope=1)
        p%expressions(1)=expr_t(kind=ex_literal,typ=ty_real)
        p%expressions(1)%value=value_t(tag=ty_real,r=real(2.3_real32,real64))
        p%expressions(2)=expr_t(kind=ex_variable,typ=ty_real,symbol=1,scope=1)
        p%code(1)=instruction_t(op=op_return,scope=1)
        p%code(2)=instruction_t(op=op_error_stop,scope=1)
        p%code(3)=instruction_t(op=op_call,symbol=1,items=[1])
    end subroutine
    subroutine check_format(fmt,types,ok)
        character(*),intent(in)::fmt
        integer,intent(in)::types(:)
        logical,intent(in)::ok
        d=diagnostic_t()
        call validate_print_format(fmt,types,d)
        call expect((d%code==0).eqv.ok,'format '//fmt)
    end subroutine
end program
