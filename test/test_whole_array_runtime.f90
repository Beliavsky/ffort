! SPDX-License-Identifier: MIT
! Independent whole-array contracts built directly as IR, without the compiler.
program test_whole_array_runtime
    use, intrinsic :: iso_fortran_env, only: int64, real32
    use fi_ir
    use fi_runtime, only: execute_program
    implicit none
    type(program_t) :: p
    type(diagnostic_t) :: d
    integer :: which, x, y, z, k, expected
    integer(int64) :: budget
    character(:), allocatable :: reason
    do which=1,34
        p=program_t(); d=diagnostic_t()
        allocate(p%symbols(4),p%expressions(256),p%code(100))
        p%ns=4; p%symbols%typ=ty_integer
        p%symbols(1)%name='a'; p%symbols(2)%name='b'
        p%symbols(3)%name='scalar'; p%symbols(4)%name='assertion'
        call array(1,-1_int64,1_int64)
        call array(2,5_int64,7_int64)
        expected=0; reason=''; budget=10000_int64
        select case(which)
        case(1)
            ! Exactly one instruction, one scalar evaluation, three stores.
            ! Re-evaluating the broadcast scalar per element exceeds this budget.
            x=lit(7_int64); call assign(1,x); budget=5_int64
        case(2)
            x=lit(7_int64); call assign(1,x)
            call check_array(1,[7_int64,7_int64,7_int64])
        case(3)
            call seed(1,[2_int64,5_int64,9_int64])
            x=variable(1); y=element(1,-1_int64); z=binary('+',x,y,ty_integer)
            call assign(1,z)
            ! In-place evaluation would incorrectly produce [4,9,13].
            call check_array(1,[4_int64,7_int64,11_int64])
        case(4)
            call seed(1,[2_int64,5_int64,9_int64])
            x=variable(1); call assign(2,x)
            ! Conformability uses extents, not matching lower bounds.
            call check_array(2,[2_int64,5_int64,9_int64])
        case(5)
            call array(2,1_int64,2_int64)
            x=variable(2); call assign(1,x)
            call expect('array assignment shapes do not conform')
        case(6)
            x=variable(1); call assign(2,x)
            call expect('uninitialized array element')
        case(7)
            x=lit(4_int64); call assign_element(1,-1_int64,x)
            x=variable(1); call assign(2,x)
            call expect('uninitialized array element')
        case(8)
            x=real_literal(-3.9_real32); call assign(1,x)
            call check_array(1,[-3_int64,-3_int64,-3_int64])
        case(9)
            p%symbols(2)%typ=ty_real
            call seed(1,[2_int64,-5_int64,9_int64])
            x=variable(1); call assign(2,x)
            do k=0,2
                x=element(2,5_int64+int(k,int64)); y=element(1,-1_int64+int(k,int64))
                z=binary('==',x,y,ty_logical); call assert_true(z)
            end do
        case(10)
            p%symbols(2)%typ=ty_real
            x=real_literal(3.9_real32); call assign(2,x)
            x=variable(2); call assign(1,x)
            call check_array(1,[3_int64,3_int64,3_int64])
        case(11)
            x=real_literal(2147483648.0_real32); call assign(1,x)
            call expect('integer overflow in real conversion')
        case(12)
            call array(1,2_int64,1_int64); call array(2,8_int64,6_int64)
            x=variable(2); call assign(1,x)
            ! Empty reads do not require any element to be initialized.
            call print_items([x])
        case(13)
            call array(1,2_int64,1_int64)
            x=lit(1_int64); y=lit(0_int64); z=binary('/',x,y,ty_integer)
            call assign(1,z); call expect('integer division by zero')
        case(14)
            x=lit(1_int64); p%expressions(x)%rank=3
            call assign(1,x); call expect('invalid expression shape')
        case(15)
            x=variable(1); p%expressions(x)%extent=-1_int64
            call assign(2,x); call expect('invalid expression shape')
        case(16)
            x=variable(1); p%expressions(x)%extent=int(max_array_elements,int64)+1_int64
            call assign(2,x); call expect('invalid expression shape')
        case(17)
            x=lit(1_int64); p%expressions(x)%extent=1_int64
            call assign(1,x); call expect('invalid scalar expression extent')
        case(18)
            x=lit(4_int64); call assign(1,x)
            call array(2,1_int64,2_int64)
            x=variable(1); p%expressions(x)%extent=2_int64
            call assign(2,x); call expect('array expression shape differs from symbol')
        case(19)
            x=lit(7_int64); call assign(1,x); budget=4_int64
            call expect('execution step limit exceeded')
        case(20)
            x=lit(7_int64); call assign(1,x)
            x=variable(1); call assign(2,x); budget=9_int64
        case(21)
            x=lit(7_int64); call assign(1,x)
            x=variable(1); call assign(2,x); budget=8_int64
            call expect('execution step limit exceeded')
        case(22)
            call seed(1,[-2_int64,5_int64,-9_int64])
            x=variable(1); y=unary('-',x,ty_integer); call assign(2,y)
            call check_array(2,[2_int64,-5_int64,9_int64])
        case(23)
            call seed(1,[-2_int64,5_int64,-9_int64])
            x=variable(1); y=intrinsic('abs',[x],ty_integer)
            z=lit(4_int64); x=intrinsic('min',[y,z],ty_integer); call assign(2,x)
            call check_array(2,[2_int64,4_int64,4_int64])
        case(24)
            p%symbols(2)%typ=ty_logical
            call seed(1,[-2_int64,5_int64,-9_int64])
            x=variable(1); y=lit(0_int64); z=binary('>',x,y,ty_logical)
            x=unary('.not.',z,ty_logical); call assign(2,x)
            x=element(2,5_int64); call assert_true(x)
            x=element(2,6_int64); y=unary('.not.',x,ty_logical); call assert_true(y)
            x=element(2,7_int64); call assert_true(x)
        case(25)
            x=lit(6_int64); call assign(3,x)
            x=variable(3); y=lit(2_int64); z=binary('*',x,y,ty_integer)
            call assign(1,z); call check_array(1,[12_int64,12_int64,12_int64])
        case(26)
            x=variable(1); call assign(3,x)
            call expect('scalar assignment requires scalar expression')
        case(27)
            x=variable(1); call assign_element(2,5_int64,x)
            call expect('scalar assignment requires scalar expression')
        case(28)
            ! The expanded PRINT limit applies even when expressions repeat.
            call array(1,1_int64,32768_int64)
            x=variable(1); y=lit(0_int64); call print_items([x,x,y])
            call expect('PRINT expanded value limit exceeded')
        case(29)
            call seed(1,[2_int64,5_int64,9_int64])
            x=lit(10_int64); y=variable(1); z=binary('-',x,y,ty_integer)
            call assign(2,z); call check_array(2,[8_int64,5_int64,1_int64])
        case(30)
            p%symbols(1)%rank=4
            call expect('only rank-one/two/three arrays are supported')
        case(31)
            call array(1,2_int64,1_int64)
            x=variable(3); call assign(1,x)
            call expect('uninitialized variable')
        case(32)
            call seed(1,[1_int64,2_int64,3_int64])
            x=variable(1); y=intrinsic('real',[x],ty_real)
            z=intrinsic('int',[y],ty_integer); call assign(2,z)
            call check_array(2,[1_int64,2_int64,3_int64])
        case(33)
            x=lit(7_int64); call assign(1,x)
            x=variable(1); y=lit(42_int64); call print_items([y,x,y])
            ! PRINT must evaluate all three expanded array elements.
            budget=10_int64
            call expect('execution step limit exceeded')
        case(34)
            call seed(1,[1_int64,2_int64,3_int64])
            x=variable(1); y=lit(2_int64); z=intrinsic('mod',[x,y],ty_integer)
            call assign(2,z); call check_array(2,[1_int64,0_int64,1_int64])
        end select
        call execute_program(p,d,budget)
        if (d%code/=expected) then
            print *, 'FAIL whole-array runtime case',which,'expected',expected,'got',d%code
            if (allocated(d%message)) print *, d%message
            error stop 1
        end if
        if (expected/=0) then
            if (.not.allocated(d%message)) error stop 'Missing diagnostic'
            if (index(d%message,reason)==0) then
                print *, 'FAIL whole-array runtime case',which,': ',d%message
                error stop 1
            end if
        end if
    end do
    print '(a)', 'PASS: 34 independent whole-array IR runtime contracts'
contains
    subroutine expect(message)
        character(*), intent(in) :: message
        expected=2; reason=message
    end subroutine
    subroutine array(sym,lo,hi)
        integer, intent(in) :: sym
        integer(int64), intent(in) :: lo,hi
        p%symbols(sym)%rank=1; p%symbols(sym)%lower_bound=lo; p%symbols(sym)%upper_bound=hi
    end subroutine
    integer function lit(n) result(idx)
        integer(int64), intent(in) :: n
        p%ne=p%ne+1; idx=p%ne
        p%expressions(idx)%kind=ex_literal; p%expressions(idx)%typ=ty_integer
        p%expressions(idx)%value%tag=ty_integer; p%expressions(idx)%value%i=n
    end function
    integer function real_literal(n) result(idx)
        real(real32), intent(in) :: n
        idx=lit(0_int64); p%expressions(idx)%typ=ty_real
        p%expressions(idx)%value%tag=ty_real; p%expressions(idx)%value%r=n
    end function
    integer function variable(sym) result(idx)
        integer, intent(in) :: sym
        p%ne=p%ne+1; idx=p%ne
        p%expressions(idx)%kind=ex_variable; p%expressions(idx)%symbol=sym
        p%expressions(idx)%typ=p%symbols(sym)%typ
        p%expressions(idx)%rank=p%symbols(sym)%rank
        if (p%symbols(sym)%rank==1) &
            p%expressions(idx)%extent=max(0_int64,p%symbols(sym)%upper_bound-p%symbols(sym)%lower_bound+1_int64)
    end function
    integer function element(sym,subscript) result(idx)
        integer, intent(in) :: sym
        integer(int64), intent(in) :: subscript
        integer :: sub
        sub=lit(subscript); idx=variable(sym)
        p%expressions(idx)%kind=ex_element; p%expressions(idx)%left=sub
        p%expressions(idx)%rank=0; p%expressions(idx)%extent=0
    end function
    integer function binary(op,a,b,typ) result(idx)
        character(*), intent(in) :: op
        integer, intent(in) :: a,b,typ
        p%ne=p%ne+1; idx=p%ne
        p%expressions(idx)%kind=ex_binary; p%expressions(idx)%typ=typ
        p%expressions(idx)%op=op; p%expressions(idx)%left=a; p%expressions(idx)%right=b
        p%expressions(idx)%rank=max(p%expressions(a)%rank,p%expressions(b)%rank)
        p%expressions(idx)%extent=max(p%expressions(a)%extent,p%expressions(b)%extent)
    end function
    integer function unary(op,a,typ) result(idx)
        character(*), intent(in) :: op
        integer, intent(in) :: a,typ
        idx=binary(op,a,a,typ); p%expressions(idx)%kind=ex_unary
    end function
    integer function intrinsic(name,args,typ) result(idx)
        character(*), intent(in) :: name
        integer, intent(in) :: args(:),typ
        integer :: j
        p%ne=p%ne+1; idx=p%ne
        p%expressions(idx)%kind=ex_call; p%expressions(idx)%typ=typ
        p%expressions(idx)%op=name; p%expressions(idx)%args=args
        do j=1,size(args)
            p%expressions(idx)%rank=max(p%expressions(idx)%rank,p%expressions(args(j))%rank)
            p%expressions(idx)%extent=max(p%expressions(idx)%extent,p%expressions(args(j))%extent)
        end do
    end function
    subroutine assign(sym,a)
        integer, intent(in) :: sym,a
        p%nc=p%nc+1; p%code(p%nc)%op=op_assign
        p%code(p%nc)%symbol=sym; p%code(p%nc)%a=a
    end subroutine
    subroutine assign_element(sym,subscript,a)
        integer, intent(in) :: sym,a
        integer(int64), intent(in) :: subscript
        integer :: sub
        sub=lit(subscript); call assign(sym,a); p%code(p%nc)%b=sub
    end subroutine
    subroutine seed(sym,values)
        integer, intent(in) :: sym
        integer(int64), intent(in) :: values(:)
        integer :: j,a
        do j=1,size(values)
            a=lit(values(j)); call assign_element(sym,p%symbols(sym)%lower_bound+j-1_int64,a)
        end do
    end subroutine
    subroutine check_array(sym,values)
        integer, intent(in) :: sym
        integer(int64), intent(in) :: values(:)
        integer :: j,a,b,c
        do j=1,size(values)
            a=element(sym,p%symbols(sym)%lower_bound+j-1_int64); b=lit(values(j))
            c=binary('==',a,b,ty_logical); call assert_true(c)
        end do
    end subroutine
    subroutine assert_true(a)
        integer, intent(in) :: a
        integer :: one,zero,failure
        p%nc=p%nc+1; p%code(p%nc)%op=op_branch
        p%code(p%nc)%a=a; p%code(p%nc)%target=p%nc+2
        p%nc=p%nc+1; p%code(p%nc)%op=op_jump; p%code(p%nc)%target=p%nc+2
        one=lit(1_int64); zero=lit(0_int64); failure=binary('/',one,zero,ty_integer)
        call assign(4,failure)
    end subroutine
    subroutine print_items(items)
        integer, intent(in) :: items(:)
        p%nc=p%nc+1; p%code(p%nc)%op=op_print; p%code(p%nc)%items=items
    end subroutine
end program
