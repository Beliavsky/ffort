! SPDX-License-Identifier: MIT
program test_grouped_formats
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
        'character(4)::s'//nl//'write(s,''(2(i2))'') [1,2]'//nl// &
        'if(s/=" 1 2") error stop "format mismatch"'//nl//'end program'
    character(:),allocatable::fmt
    integer::which,i,wr
    do which=1,8
        call parse_subset(source,p,d)
        call require(d%code==0,'baseline parse')
        wr=0
        do i=1,p%nc
            if(p%code(i)%op==op_write_internal) wr=i
        end do
        call require(wr>0,'internal output instruction')
        if(which==1) then
            call verify_frontend(source,p,d)
            call require(d%code==0,'baseline adapter')
            call execute_program(p,d)
            call require(d%code==0,'grouped internal write')
        else if(which==2) then
            p%code(wr)%format='(i2,2(i2))'
            call verify_frontend(source,p,d)
            call require(d%code/=0,'changed grouped IR rejected by adapter')
        else
            select case(which)
            case(3);p%code(wr)%format='(2(f2.0))'
            case(4);p%code(wr)%format='(i2)'
            case(5);p%code(wr)%format='(2("no data"))'
            case(6);p%code(wr)%format='(0(i2))'
            case(7);p%code(wr)%format='(65536(2("")))'
            case(8);p%code(wr)%format='(2(i2))junk'
            end select
            call execute_program(p,d)
            call require(d%code==2,'runtime rejects invalid grouped transfer without output')
        end if
    end do
    call valid('(a,2(i0))',[ty_character,ty_integer,ty_integer,ty_integer],.true.,'last group reversion')
    call invalid('(a,2(i0))',[ty_character,ty_integer,ty_integer,ty_character],.true.,'reversion type mismatch')
    call invalid('(i0,2("tail"))',[ty_integer,ty_integer],.true.,'reversion has no data')
    call invalid('(2(i0))',[ty_integer,ty_integer,ty_integer],.false.,'internal reversion blocked')
    call valid('(2(2(i0)))',[ty_integer,ty_integer,ty_integer,ty_integer],.false.,'nested repetitions')
    call valid('(65536(""))',[integer::],.true.,'bounded zero-length literal repetition')
    call invalid('(65536(2("")))',[integer::],.true.,'nested zero-length operation cap')
    call valid('(65536("x"))',[integer::],.true.,'exact byte cap')
    call invalid('(65536(2("x")))',[integer::],.true.,'nested byte multiplication cap')
    fmt='('//repeat('(',31)//'i0,i0'//repeat(')',31)//')'
    call valid(fmt,[ty_integer,ty_integer],.false.,'64 format nodes')
    fmt='('//repeat('(',31)//'i0,i0,i0'//repeat(')',31)//')'
    call invalid(fmt,[ty_integer,ty_integer,ty_integer],.false.,'65 format nodes')
    fmt='('//repeat('(',32)//'i0'//repeat(')',32)//')'
    call invalid(fmt,[ty_integer],.false.,'32 nested groups')
    d=diagnostic_t()
    call validate_print_format('(2(1x,i0))',[ty_integer],d,counts=[-1_int64],allow_reversion=.true.)
    call require(d%code==0,'dynamic grouped descriptor association deferred')
    d=diagnostic_t()
    call validate_print_format('(2(i0,/))',[ty_integer],d,counts=[-1_int64],allow_reversion=.true.)
    call require(d%code==0,'dynamic shape admits supported nested slash grammar')
    print '(a)','PASS: grouped formats, adapter and runtime mutations, node/byte/operation boundaries'
contains
    subroutine valid(fmt,types,revert,label)
        character(*),intent(in)::fmt,label
        integer,intent(in)::types(:)
        logical,intent(in)::revert
        d=diagnostic_t()
        call validate_print_format(fmt,types,d,allow_reversion=revert)
        call require(d%code==0,label)
    end subroutine
    subroutine invalid(fmt,types,revert,label)
        character(*),intent(in)::fmt,label
        integer,intent(in)::types(:)
        logical,intent(in)::revert
        d=diagnostic_t()
        call validate_print_format(fmt,types,d,allow_reversion=revert)
        call require(d%code/=0,label)
    end subroutine
    subroutine require(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        if(ok) return
        print *,label
        if(allocated(d%message)) print *,d%message
        error stop 'grouped format regression'
    end subroutine
end program
