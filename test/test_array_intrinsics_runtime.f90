! SPDX-License-Identifier: MIT
! Exercise the runtime independently of the adapter, including malformed IR.
program test_array_intrinsics_runtime
    use, intrinsic :: iso_fortran_env, only: int64
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_runtime, only: execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        'integer :: a(2,3),b(3,2),c(2,2),v(3),r'//nl//'logical :: m(2,3)'//nl// &
        'a=1'//nl//'b=2'//nl//'m=.true.'//nl//'v=sum(a,1,m)'//nl// &
        'c=matmul(a,b)'//nl//'r=dot_product(v,v)'//nl// &
        "if (r/=12) error stop 'dot result'"//nl// &
        "if (sum(c)/=24) error stop 'matrix result'"//nl//'end program p'
    integer::which,e,k,child
    integer(int64)::budget
    do which=1,21
        call parse_subset(source,p,d)
        if(d%code/=0) error stop 'baseline failed to parse'
        e=find_call('sum');budget=10000_int64
        select case(which)
        case(2);p%expressions(e)%rank=0;p%expressions(e)%extent=0_int64
        case(3);p%expressions(e)%typ=ty_logical
        case(4);p%expressions(e)%args(1)=0
        case(5);p%expressions(e)%args(1)=p%ne+1
        case(6);p%expressions(e)%args(1)=e
        case(7);p%expressions(e)%args(1)=p%expressions(e)%args(2)
        case(8);p%expressions(e)%args(2)=p%expressions(e)%args(1)
        case(9);p%expressions(e)%args(3)=p%expressions(e)%args(1)
        case(10);p%expressions(e)%args=[integer::]
        case(11);deallocate(p%expressions(e)%args)
        case(12);p%expressions(e)%args=[p%expressions(e)%args,1]
        case(13)
            child=p%expressions(e)%args(2)
            p%expressions(child)%value%i=3_int64
        case(14);p%expressions(e)%extent=2_int64
        case(15:19)
            e=find_call('matmul')
            select case(which)
            case(15);p%expressions(e)%rank=1;p%expressions(e)%dims=0_int64
            case(16);p%expressions(e)%typ=ty_real;p%expressions(e)%real_kind=8
            case(17);p%expressions(e)%args=p%expressions(e)%args(:1)
            case(18);p%expressions(e)%args(2)=p%expressions(e)%args(1)
            case(19);p%expressions(e)%args(1)=e
            end select
        case(20)
            e=find_call('dot_product');k=find_call('matmul')
            p%expressions(e)%args(1)=p%expressions(k)%args(1)
        case(21);budget=30_int64
        end select
        call execute_program(p,d,max_steps=budget)
        if(which==1) then
            if(d%code/=0) then
                print *,d%message
                error stop 'valid intrinsic runtime failed'
            end if
        else if(d%code/=2) then
            print *,which,d%code
            error stop 'forged intrinsic runtime admitted'
        end if
    end do
    print '(a)','PASS: array-intrinsic runtime baseline, 19 malformed-IR checks and shared budget'
contains
    integer function find_call(name) result(index)
        character(*),intent(in)::name
        do index=1,p%ne
            if(p%expressions(index)%kind==ex_call.and.p%expressions(index)%op==name) return
        end do
        error stop 'missing intrinsic in test'
    end function
end program
