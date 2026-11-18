! SPDX-License-Identifier: MIT
! Direct-IR section contracts, independent of source parsing and FortFront.
program test_section_runtime
    use, intrinsic :: iso_fortran_env, only: int64, real32
    use fi_ir
    use fi_runtime, only: execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    integer::which,x,y,z,t,expected
    integer(int64)::budget
    character(:),allocatable::reason
    do which=1,25
        p=program_t();d=diagnostic_t()
        allocate(p%symbols(4),p%expressions(256),p%code(100))
        p%ns=4;p%symbols%typ=ty_integer
        p%symbols(1)%name='a';p%symbols(2)%name='b'
        p%symbols(3)%name='scalar';p%symbols(4)%name='assertion'
        call array(1,1_int64,3_int64);call array(2,1_int64,3_int64)
        expected=0;reason='';budget=10000_int64
        select case(which)
        case(1)
            call seed(1,[1_int64,2_int64,3_int64])
            t=section(1,1,3,1);x=section(1,3,1,-1)
            call assign_section(t,x);call check_array(1,[3_int64,2_int64,1_int64])
        case(2)
            call seed(1,[1_int64,2_int64,3_int64])
            t=section(1,1,3,1)
            x=element(1,1_int64);p%expressions(t)%left=x
            x=section(1,3,1,-1);call assign_section(t,x)
            ! Target lower endpoint reads a(1), overwritten by the first store.
            call check_array(1,[3_int64,2_int64,1_int64])
        case(3)
            t=section(1,1,3,0);x=lit(1_int64);call assign_section(t,x)
            call expect('section stride is zero')
        case(4)
            t=section(1,0,2,1);x=lit(1_int64);call assign_section(t,x)
            call expect('out of bounds')
        case(5)
            t=section(1,1,4,1);x=lit(1_int64);call assign_section(t,x)
            call expect('out of bounds')
        case(6)
            t=section(1,4,1,-1);x=lit(1_int64);call assign_section(t,x)
            call expect('out of bounds')
        case(7)
            t=section(1,3,0,-1);x=lit(1_int64);call assign_section(t,x)
            call expect('out of bounds')
        case(8)
            ! Upper endpoint 4 is not selected by 1:4:2.
            call seed(1,[1_int64,2_int64,3_int64])
            t=section(1,1,4,2);x=lit(9_int64);call assign_section(t,x)
            call check_array(1,[9_int64,2_int64,9_int64])
        case(9)
            ! Endpoint 0 is not selected by 3:0:-2.
            call seed(1,[1_int64,2_int64,3_int64])
            t=section(1,3,0,-2);x=lit(9_int64);call assign_section(t,x)
            call check_array(1,[9_int64,2_int64,9_int64])
        case(10)
            t=section(1,999,998,1);x=section(2,999,998,1)
            call assign_section(t,x) ! Empty uninitialized arrays are not read.
        case(11)
            t=section(1,-999,-998,-1);x=lit(7_int64);call assign_section(t,x)
        case(12)
            t=section(1,1,3,1);x=variable(2);p%expressions(t)%left=x
            x=lit(7_int64);call assign_section(t,x)
            call expect('section triplet must be scalar INTEGER')
        case(13)
            t=section(1,1,3,1);x=real_literal(1.0_real32);p%expressions(t)%right=x
            x=lit(7_int64);call assign_section(t,x)
            call expect('section triplet must be scalar INTEGER')
        case(14)
            t=section(1,1,3,1);x=real_literal(1.0_real32)
            p%expressions(x)%typ=ty_integer;p%expressions(t)%stride=x
            x=lit(7_int64);call assign_section(t,x)
            call expect('section triplet must be scalar INTEGER')
        case(15)
            t=section(1,1,3,1);x=lit(7_int64);call assign_section(t,x);budget=9_int64
        case(16)
            t=section(1,1,3,1);x=lit(7_int64);call assign_section(t,x);budget=8_int64
            call expect('execution step limit exceeded')
        case(17)
            t=section(1,1,3,1)
            p%expressions(t)%left=0;p%expressions(t)%right=0;p%expressions(t)%stride=0
            x=lit(7_int64);call assign_section(t,x);budget=6_int64
        case(18)
            ! Declared bounds default independently of the stride sign.
            t=section(1,1,3,-1);p%expressions(t)%left=0;p%expressions(t)%right=0
            x=section(2,1,3,-1);p%expressions(x)%left=0;p%expressions(x)%right=0
            call assign_section(t,x)
        case(19)
            t=section(1,1,3,1);x=section(2,1,2,1);call assign_section(t,x)
            call expect('array assignment shapes do not conform')
        case(20)
            t=section(1,1,3,1);x=section(2,1,3,1);call assign_section(t,x)
            call expect('uninitialized array element')
        case(21)
            t=section(1,1,3,1);p%expressions(t)%extent=3_int64
            x=lit(1_int64);call assign_section(t,x);call expect('invalid section expression shape')
        case(22)
            t=section(1,1,3,1);x=lit(1_int64);call assign_section(t,x)
            p%code(p%nc)%b=p%expressions(t)%left
            call expect('invalid section assignment target')
        case(23)
            t=section(1,1,3,1);x=lit(1_int64);call assign_section(t,x)
            p%code(p%nc)%symbol=2;call expect('invalid section assignment target')
        case(24)
            call seed(1,[1_int64,2_int64,3_int64])
            t=section(1,3,1,-1);x=lit(-2147483648_int64);p%expressions(t)%stride=x
            x=lit(9_int64);call assign_section(t,x)
            call check_array(1,[1_int64,2_int64,9_int64])
        case(25)
            t=section(1,999,998,1);x=lit(1_int64);y=lit(0_int64)
            z=binary('/',x,y,ty_integer);call assign_section(t,z)
            call expect('integer division by zero')
        end select
        call execute_program(p,d,budget)
        if(d%code/=expected) then
            print *,'FAIL section runtime case',which,'expected',expected,'got',d%code
            if(allocated(d%message)) print *,d%message
            error stop 1
        end if
        if(expected/=0) then
            if(.not.allocated(d%message)) error stop 'Missing diagnostic'
            if(index(d%message,reason)==0) then
                print *,'FAIL section runtime case',which,': ',d%message
                error stop 1
            end if
        end if
    end do
    print '(a)','PASS: 25 independent section IR runtime contracts'
contains
    integer function section(sym,lo,hi,step) result(idx)
        integer,intent(in)::sym,lo,hi,step
        integer::a,b,c
        a=lit(int(lo,int64));b=lit(int(hi,int64));c=lit(int(step,int64))
        idx=variable(sym);p%expressions(idx)%kind=ex_section
        p%expressions(idx)%left=a;p%expressions(idx)%right=b;p%expressions(idx)%stride=c
        p%expressions(idx)%rank=1;p%expressions(idx)%extent=-1_int64
    end function
    subroutine assign_section(target,rhs)
        integer,intent(in)::target,rhs
        call assign(p%expressions(target)%symbol,rhs)
        p%code(p%nc)%c=target
    end subroutine
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
