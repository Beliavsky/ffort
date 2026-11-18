! SPDX-License-Identifier: MIT
program test_array_intrinsics_frontend
    use, intrinsic :: iso_fortran_env, only: int64
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
        'real(8) :: a(2,3),b(3,2),v(3)'//nl//'logical :: m(2,3)'//nl// &
        'a=1.0_8'//nl//'b=2.0_8'//nl//'v=3.0_8'//nl//'m=.true.'//nl// &
        'print *,sum(a,1,m),product(a),minval(a),maxval(a)'//nl// &
        'print *,matmul(a,b),dot_product(v,v)'//nl//'end program p'
    integer::which,e,child
    do which=1,26
        call parse_subset(source,p,d)
        call require_ok('baseline parse')
        e=find_call('sum')
        select case(which)
        case(2);p%expressions(e)%rank=0
        case(3);p%expressions(e)%rank=2
        case(4);p%expressions(e)%extent=3_int64
        case(5);p%expressions(e)%dims=[3_int64,1_int64,1_int64]
        case(6);p%expressions(e)%typ=ty_integer
        case(7);p%expressions(e)%real_kind=4
        case(8);p%expressions(e)%op='product'
        case(9);p%expressions(e)%args(1)=p%expressions(e)%args(2)
        case(10);p%expressions(e)%args(2)=p%expressions(e)%args(1)
        case(11);p%expressions(e)%args(3)=p%expressions(e)%args(1)
        case(12);p%expressions(e)%args(1)=0
        case(13);p%expressions(e)%args(1)=p%ne+1
        case(14);p%expressions(e)%args(1)=e
        case(15);p%expressions(e)%args=p%expressions(e)%args(:1)
        case(16);deallocate(p%expressions(e)%args)
        case(17);p%expressions(e)%args=[integer::]
        case(18)
            child=p%expressions(e)%args(2)
            p%expressions(child)%typ=ty_real
        case(19:23)
            e=find_call('matmul')
            select case(which)
            case(19);p%expressions(e)%rank=1
            case(20);p%expressions(e)%extent=4_int64;p%expressions(e)%dims=[2_int64,2_int64,1_int64]
            case(21);p%expressions(e)%typ=ty_logical
            case(22);p%expressions(e)%real_kind=4
            case(23);p%expressions(e)%args=p%expressions(e)%args(:1)
            end select
        case(24:26)
            e=find_call('dot_product')
            if(which==24) p%expressions(e)%rank=1
            if(which==25) p%expressions(e)%typ=ty_integer
            if(which==26) p%expressions(e)%args(1)=p%expressions(find_call('sum'))%args(1)
        end select
        call verify_frontend(source,p,d)
        if(which==1) then
            call require_ok('baseline verification')
        else if(d%code==0) then
            print *,which
            error stop 'forged array intrinsic admitted'
        end if
    end do
    print '(a)','PASS: array-intrinsic baseline and 25 adapter mutations'
contains
    integer function find_call(name) result(index)
        character(*),intent(in)::name
        do index=1,p%ne
            if(p%expressions(index)%kind==ex_call.and.p%expressions(index)%op==name) return
        end do
        error stop 'missing intrinsic in test'
    end function
    subroutine require_ok(label)
        character(*),intent(in)::label
        if(d%code==0) return
        print *,label,d%message
        error stop 'array intrinsic frontend test failed'
    end subroutine
end program
