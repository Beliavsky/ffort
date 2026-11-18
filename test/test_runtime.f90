! SPDX-License-Identifier: MIT
! Independent IR-level runtime contracts, without compiler/parser dependencies.
program test_runtime
    use, intrinsic :: iso_fortran_env, only: int64, real32
    use fi_ir
    use fi_runtime
    implicit none
    type(program_t) :: p
    type(diagnostic_t) :: d
    integer :: which,x,y,z,k,expected
    character(:),allocatable :: reason
    do which=1,53
        p=program_t()
        d=diagnostic_t()
        allocate(p%symbols(4),p%expressions(1500),p%code(100))
        p%ns=2
        p%symbols(1)%name='i'
        p%symbols(2)%name='j'
        p%symbols%typ=ty_integer
        expected=0
        reason=''
        select case(which)
        case(1)
            x=lit(-2147483647_int64); y=lit(1_int64); z=bin('-',x,y)
            call assert_integer(z,-2147483648_int64)
        case(2)
            x=lit(2147483647_int64); y=lit(1_int64); z=bin('+',x,y)
            call assign(2,z); expected=2; reason='integer overflow'
        case(3)
            x=lit(-2147483648_int64); y=lit(-1_int64); z=bin('/',x,y)
            call assign(2,z); expected=2; reason='integer overflow'
        case(4)
            x=lit(-2_int64); y=lit(31_int64); z=bin('**',x,y)
            call assert_integer(z,-2147483648_int64)
        case(5)
            x=lit(2_int64); y=lit(31_int64); z=bin('**',x,y)
            call assign(2,z); expected=2; reason='integer overflow'
        case(6)
            x=lit(-1_int64); y=lit(-2147483648_int64); z=bin('**',x,y)
            call assert_integer(z,1_int64)
        case(7)
            x=lit(0_int64); y=lit(-1_int64); z=bin('**',x,y)
            call assign(2,z); expected=2; reason='zero raised to negative power'
        case(8)
            x=variable(1); call assign(2,x); expected=2; reason='uninitialized'
        case(9)
            x=lit(1_int64); y=lit(5_int64); z=lit(2_int64)
            call doloop(x,y,z); x=variable(1); call assert_integer(x,7_int64)
        case(10)
            x=lit(5_int64); y=lit(1_int64); z=lit(-2_int64)
            call doloop(x,y,z); x=variable(1); call assert_integer(x,-1_int64)
        case(11)
            x=lit(5_int64); y=lit(1_int64); z=lit(2_int64)
            call doloop(x,y,z); x=variable(1); call assert_integer(x,5_int64)
        case(12)
            x=lit(1_int64); y=lit(5_int64); z=lit(0_int64)
            call doloop(x,y,z); expected=2; reason='DO step is zero'
        case(13)
            x=lit(2147483647_int64); y=lit(2147483647_int64); z=lit(1_int64)
            call doloop(x,y,z); expected=2; reason='integer overflow'
        case(14)
            x=lit(1_int64); y=lit(5_int64); z=lit(2_int64)
            call doloop(x,y,z); p%code(2)%symbol=1
            expected=2; reason='assignment to active DO variable'
        case(15)
            x=lit(1_int64); y=lit(2147483647_int64); z=lit(1_int64)
            call doloop(x,y,z); expected=2; reason='execution step limit exceeded'
        case(16)
            x=real_lit(3.9_real32); call assign(1,x)
            x=variable(1); call assert_integer(x,3_int64)
        case(17)
            x=real_lit(2147483648.0_real32); call assign(1,x)
            expected=2; reason='integer overflow in real conversion'
        case(18)
            x=real_lit(huge(1.0_real32)); z=bin('*',x,x)
            p%expressions(z)%typ=ty_real
            call assign(1,z); expected=2; reason='non-finite real result'
        case(19)
            x=lit(-7_int64); y=lit(3_int64); z=bin('/',x,y)
            call assert_integer(z,-2_int64)
        case(20)
            x=lit(-2_int64); y=lit(-3_int64); z=bin('**',x,y)
            call assert_integer(z,0_int64)
        case(21)
            x=lit(-2147483648_int64); z=intrinsic('abs',[x],ty_integer)
            call assign(2,z); expected=2; reason='integer overflow'
        case(22)
            x=lit(1_int64); y=lit(0_int64); z=intrinsic('mod',[x,y],ty_integer)
            call assign(2,z); expected=2; reason='MOD divisor is zero'
        case(23)
            x=real_lit(-2.0_real32); y=real_lit(2.0_real32); z=bin('**',x,y)
            p%expressions(z)%typ=ty_real
            call assign(2,z); expected=2; reason='negative base with real exponent'
        case(24)
            x=lit(16777217_int64); call assert_integer(x,16777217_int64)
            x=lit(16777217_int64); y=lit(16777216_int64); z=bin('>',x,y)
            p%expressions(z)%typ=ty_logical; call assert_condition(z)
        case(25)
            x=lit(1_int64); y=lit(3_int64)
            call doloop(x,y,0); x=variable(1); call assert_integer(x,4_int64)
        case(26)
            ! The upper bound reads j once; the loop body changes j to zero.
            x=lit(3_int64); call assign(2,x)
            x=lit(1_int64); y=variable(2)
            call doloop(x,y,0); x=variable(1); call assert_integer(x,4_int64)
        case(27)
            x=lit(1_int64); y=lit(0_int64); z=bin('/',x,y)
            call assign(2,z); expected=2; reason='integer division by zero'
        case(28)
            x=real_lit(1.0_real32); y=real_lit(0.0_real32); z=bin('/',x,y)
            p%expressions(z)%typ=ty_real
            call assign(2,z); expected=2; reason='real division by zero'
        case(29)
            x=lit(0_int64)
            do k=1,600
                y=lit(1_int64); x=bin('+',x,y)
            end do
            call assign(2,x); expected=2; reason='expression nesting limit exceeded'
        case(30)
            x=lit(-8_int64); y=lit(3_int64); z=intrinsic('mod',[x,y],ty_integer)
            call assert_integer(z,-2_int64)
            x=lit(7_int64); y=lit(-3_int64); z=lit(12_int64)
            k=intrinsic('min',[x,y,z],ty_integer); call assert_integer(k,-3_int64)
            k=intrinsic('max',[x,y,z],ty_integer); call assert_integer(k,12_int64)
        case(31)
            x=real_lit(tiny(1.0_real32)); call assign(1,x)
            x=variable(1); call assert_integer(x,0_int64)
        case(32)
            x=real_lit(-3.9_real32); call assign(1,x)
            x=variable(1); call assert_integer(x,-3_int64)
        case(33)
            call array(1,-2_int64,2_int64)
            x=lit(-2_int64); y=lit(42_int64); call assign_element(1,x,y)
            z=element(1,x); call assert_integer(z,42_int64)
        case(34)
            call array(1,1_int64,2_int64)
            x=lit(1_int64); y=lit(7_int64); call assign_element(1,x,y)
            x=lit(2_int64); z=element(1,x); call assign(2,z)
            expected=2; reason='uninitialized array element'
        case(35)
            call array(1,0_int64,2_int64)
            x=lit(-1_int64); z=element(1,x); call assign(2,z)
            expected=2; reason='out of bounds'
        case(36)
            call array(1,0_int64,2_int64)
            x=lit(3_int64); y=lit(7_int64); call assign_element(1,x,y)
            expected=2; reason='out of bounds'
        case(37)
            call array(1,5_int64,3_int64)
            x=lit(4_int64); z=element(1,x); call assign(2,z)
            expected=2; reason='out of bounds'
        case(38)
            call array(1,1_int64,2_int64)
            x=real_lit(1.0_real32); y=lit(7_int64); call assign_element(1,x,y)
            expected=2; reason='subscript must be INTEGER'
        case(39)
            call array(1,1_int64,2_int64)
            x=lit(1_int64); y=real_lit(-3.9_real32); call assign_element(1,x,y)
            z=element(1,x); call assert_integer(z,-3_int64)
        case(40)
            call array(1,2147483647_int64,2147483647_int64)
            x=lit(2147483647_int64); y=lit(99_int64); call assign_element(1,x,y)
            z=element(1,x); call assert_integer(z,99_int64)
        case(41)
            call array(1,-2147483648_int64,-2147483648_int64)
            x=lit(-2147483648_int64); y=lit(12_int64); call assign_element(1,x,y)
            z=element(1,x); call assert_integer(z,12_int64)
        case(42)
            call array(1,-2147483648_int64,2147483647_int64)
            expected=2; reason='array element limit exceeded'
        case(43)
            call array(1,1_int64,2_int64)
            x=variable(1); call assign(2,x)
            expected=2; reason='array expression requires an array context'
        case(44)
            call array(1,1_int64,2_int64)
            x=lit(1_int64); y=lit(2_int64); call doloop(x,y,0)
            expected=2; reason='DO variable must be an INTEGER scalar'
        case(45)
            call array(1,1_int64,2_int64)
            x=lit(1_int64); y=lit(2_int64); call assign_element(1,x,y)
            x=lit(2_int64); y=lit(8_int64); call assign_element(1,x,y)
            x=lit(1_int64); y=element(1,x); z=element(1,y)
            call assert_integer(z,8_int64)
        case(46)
            call array(1,1_int64,65536_int64)
            x=lit(65536_int64); y=lit(23_int64); call assign_element(1,x,y)
            z=element(1,x); call assert_integer(z,23_int64)
        case(47)
            call parameter_constant(1,32_int64)
            x=variable(1); call assert_integer(x,32_int64)
        case(48)
            call parameter_constant(1,32_int64)
            x=lit(10_int64); call assign(1,x)
            expected=2; reason='assignment to PARAMETER constant'
        case(49)
            call parameter_constant(1,32_int64)
            x=lit(1_int64); y=lit(5_int64); call doloop(x,y,0)
            expected=2; reason='DO variable cannot be a PARAMETER'
        case(50)
            call parameter_constant(1,32_int64)
            p%symbols(1)%parameter_ready=.false.
            x=variable(1); call assign(2,x)
            expected=2; reason='PARAMETER value is not defined'
        case(51)
            call parameter_constant(1,32_int64)
            p%symbols(1)%constant_value%tag=ty_real
            x=variable(1); call assign(2,x)
            expected=2; reason='PARAMETER value type mismatch'
        case(52)
            call parameter_constant(1,2147483648_int64)
            x=variable(1); call assign(2,x)
            expected=2; reason='integer overflow'
        case(53)
            call parameter_constant(1,32_int64)
            p%symbols(1)%rank=1
            x=variable(1); call assign(2,x)
            expected=2; reason='PARAMETER must be scalar'
        end select
        if(which==15) then
            call execute_program(p,d,100_int64)
        else
            call execute_program(p,d,10000_int64)
        end if
        if(d%code/=expected) then
            print *, 'FAIL runtime case',which,'expected code',expected,'got',d%code
            if(allocated(d%message)) print *,d%message
            error stop 1
        end if
        if(expected/=0) then
            if(.not.allocated(d%message)) error stop 'Missing runtime diagnostic'
            if(index(d%message,reason)==0) then
                print *, 'FAIL runtime case',which,'wrong diagnostic: ',d%message
                error stop 1
            end if
        end if
    end do
    print '(a)', 'PASS: 53 independent IR runtime contracts'
contains
    subroutine parameter_constant(symbol,n)
        integer,intent(in)::symbol
        integer(int64),intent(in)::n
        p%symbols(symbol)%is_parameter=.true.
        p%symbols(symbol)%parameter_ready=.true.
        p%symbols(symbol)%constant_value%tag=ty_integer
        p%symbols(symbol)%constant_value%i=n
    end subroutine
    integer function lit(n) result(idx)
        integer(int64),intent(in)::n
        p%ne=p%ne+1; idx=p%ne
        p%expressions(idx)%kind=ex_literal; p%expressions(idx)%typ=ty_integer
        p%expressions(idx)%value%tag=ty_integer; p%expressions(idx)%value%i=n
    end function
    integer function real_lit(n) result(idx)
        real(real32),intent(in)::n
        idx=lit(0_int64)
        p%expressions(idx)%typ=ty_real; p%expressions(idx)%value%tag=ty_real
        p%expressions(idx)%value%r=n
    end function
    integer function variable(n) result(idx)
        integer,intent(in)::n
        p%ne=p%ne+1; idx=p%ne
        p%expressions(idx)%kind=ex_variable; p%expressions(idx)%typ=ty_integer
        p%expressions(idx)%symbol=n
    end function
    integer function bin(op,a,b) result(idx)
        character(*),intent(in)::op
        integer,intent(in)::a,b
        p%ne=p%ne+1; idx=p%ne
        p%expressions(idx)%kind=ex_binary; p%expressions(idx)%typ=ty_integer
        p%expressions(idx)%op=op; p%expressions(idx)%left=a; p%expressions(idx)%right=b
    end function
    integer function intrinsic(name,args,typ) result(idx)
        character(*),intent(in)::name
        integer,intent(in)::args(:),typ
        p%ne=p%ne+1; idx=p%ne
        p%expressions(idx)%kind=ex_call; p%expressions(idx)%typ=typ
        p%expressions(idx)%op=name; p%expressions(idx)%args=args
    end function
    subroutine array(symbol,lo,hi)
        integer,intent(in)::symbol
        integer(int64),intent(in)::lo,hi
        p%symbols(symbol)%rank=1
        p%symbols(symbol)%lower_bound=lo
        p%symbols(symbol)%upper_bound=hi
    end subroutine
    integer function element(symbol,index) result(idx)
        integer,intent(in)::symbol,index
        idx=variable(symbol)
        p%expressions(idx)%kind=ex_element
        p%expressions(idx)%left=index
    end function
    subroutine assign_element(symbol,index,a)
        integer,intent(in)::symbol,index,a
        call assign(symbol,a)
        p%code(p%nc)%b=index
    end subroutine
    subroutine assign(symbol,a)
        integer,intent(in)::symbol,a
        p%nc=p%nc+1; p%code(p%nc)%op=op_assign
        p%code(p%nc)%symbol=symbol; p%code(p%nc)%a=a
    end subroutine
    subroutine assert_integer(a,n)
        integer,intent(in)::a
        integer(int64),intent(in)::n
        integer::b,c
        b=lit(n); c=bin('==',a,b); p%expressions(c)%typ=ty_logical
        call assert_condition(c)
    end subroutine
    subroutine assert_condition(a)
        integer,intent(in)::a
        integer::b,c,failure
        ! A false assertion evaluates 1/0; a true assertion skips it entirely.
        p%nc=p%nc+1; p%code(p%nc)%op=op_branch
        p%code(p%nc)%a=a; p%code(p%nc)%target=p%nc+2
        p%nc=p%nc+1; p%code(p%nc)%op=op_jump; p%code(p%nc)%target=p%nc+2
        b=lit(1_int64); c=lit(0_int64); failure=bin('/',b,c)
        call assign(2,failure)
    end subroutine
    subroutine doloop(a,b,c)
        integer,intent(in)::a,b,c
        integer::entry,body,zero
        p%nc=p%nc+1; entry=p%nc
        p%code(entry)%op=op_do; p%code(entry)%symbol=1
        p%code(entry)%a=a; p%code(entry)%b=b; p%code(entry)%c=c
        body=entry+1
        zero=lit(0_int64); call assign(2,zero)
        p%nc=p%nc+1; p%code(p%nc)%op=op_next
        p%code(p%nc)%symbol=1 ! Cached loop identity must match OP_DO.
        p%code(p%nc)%a=entry; p%code(p%nc)%target=body
        p%code(entry)%target=p%nc+1
    end subroutine
end program
