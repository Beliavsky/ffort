! SPDX-License-Identifier: MIT
program test_formatted_arrays
    use, intrinsic :: iso_fortran_env, only: int64
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: execute_program, validate_print_format
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program main'//nl//'implicit none'//nl// &
        'integer::a(2,2)'//nl//'character(12)::s'//nl// &
        'a=reshape([1,2,3,4],[2,2])'//nl// &
        'write(s,''(4i3)'') a'//nl// &
        'if(s/="  1  2  3  4") error stop "format mismatch"'//nl// &
        'print ''(3i3)'',a'//nl//'end program'
    integer::which,i,pr,wr,x
    do which=1,8
        call parse_subset(source,p,d)
        call require(d%code==0,'baseline parse')
        pr=0;wr=0
        do i=1,p%nc
            if(p%code(i)%op==op_print) pr=i
            if(p%code(i)%op==op_write_internal) wr=i
        end do
        call require(min(pr,wr)>0,'output instructions')
        x=p%code(pr)%items(1)
        select case(which)
        case(2);p%code(pr)%format='(4i3)'
        case(3);p%code(pr)%items=[integer::]
        case(4);p%expressions(x)%rank=1
        case(5);p%expressions(x)%extent=3
        case(6);p%code(wr)%format='(4i4)'
        case(7);p%code(wr)%symbol=1
        case(8);p%code(wr)%items=[integer::]
        end select
        call verify_frontend(source,p,d)
        if(which==1) then
            call require(d%code==0,'baseline adapter')
            call execute_program(p,d)
            call require(d%code==0,'array internal WRITE and PRINT')
        else
            call require(d%code/=0,'forged output IR rejected')
        end if
    end do
    do which=1,3
        call parse_subset(source,p,d)
        call require(d%code==0,'runtime mutation baseline')
        do i=1,p%nc
            if(p%code(i)%op==op_write_internal) wr=i
        end do
        select case(which)
        case(1);p%code(wr)%format='(4f3.0)'
        case(2);p%code(wr)%format='("no data")'
        case(3);p%code(wr)%format='(2i3)'
        end select
        call execute_program(p,d)
        call require(d%code==2,'runtime formatter rejects malformed transfer without output')
    end do
    d=diagnostic_t()
    call validate_print_format('(2i3)',[ty_integer],d,counts=[5_int64],allow_reversion=.true.)
    call require(d%code==0,'known array reversion')
    d=diagnostic_t()
    call validate_print_format('(2i3)',[ty_integer],d,counts=[5_int64])
    call require(d%code/=0,'internal record exhaustion')
    d=diagnostic_t()
    call validate_print_format('(2i3)',[ty_real],d,counts=[5_int64],allow_reversion=.true.)
    call require(d%code/=0,'known array type rejection')
    d=diagnostic_t()
    call validate_print_format('(2i3)',[ty_real],d,counts=[-1_int64],allow_reversion=.true.)
    call require(d%code==0,'dynamic association deferred')
    d=diagnostic_t()
    call validate_print_format('(2(i3,/))',[ty_integer],d,counts=[-1_int64],allow_reversion=.true.)
    call require(d%code==0,'dynamic shape admits supported slash grammar')
    d=diagnostic_t()
    call validate_print_format('(2i3)',[ty_real],d,counts=[0_int64],allow_reversion=.true.)
    call require(d%code==0,'empty array consumes no descriptor')
    print '(a)','PASS: formatted array execution, seven adapter mutations, three runtime rejections and six boundary checks'
contains
    subroutine require(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        if(ok) return
        print *,label
        if(allocated(d%message)) print *,d%message
        error stop 'formatted array regression'
    end subroutine
end program
