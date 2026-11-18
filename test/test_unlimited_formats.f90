! SPDX-License-Identifier: MIT
program test_unlimited_formats
    use, intrinsic :: iso_fortran_env,only:int64
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program,validate_print_format
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl// &
        'implicit none'//nl// &
        'character(16)::s'//nl// &
        'write(s,''("h",*(g0))'')1,''x'',.true.'//nl// &
        'if(s/=''h1xT'')error stop 1'//nl// &
        'end program'
    type(program_t)::p,q
    type(diagnostic_t)::d
    character(:),allocatable::fmt
    integer,allocatable::types(:)
    integer::i,j,wr,checks
    checks=0
    call parse_subset(source,p,d);call require(d%code==0,'baseline parse')
    call verify_frontend(source,p,d);call require(d%code==0,'baseline adapter')
    call execute_program(p,d);call require(d%code==0,'internal unlimited G0 values')
    wr=0
    do i=1,p%nc
        if(p%code(i)%op==op_write_internal)wr=i
    end do
    call require(wr>0,'internal write found')
    q=p;q%code(wr)%format='(*(g0))'
    d=diagnostic_t();call verify_frontend(source,q,d)
    call require(d%code/=0,'adapter checks exact source format')
    do j=1,8
        q=p
        select case(j)
        case(1);q%code(wr)%format='(*(g0),a)'
        case(2);q%code(wr)%format='(*(""))'
        case(3);q%code(wr)%format='(2(*(g0)))'
        case(4);q%code(wr)%format='(*(i0))'
        case(5);q%code(wr)%format='(g0)'
        case(6);q%code(wr)%format='(*(g0.6))'
        case(7);q%code(wr)%format='(*(g0))junk'
        case(8);q%code(wr)%format='(*(65536("")))'
        end select
        d=diagnostic_t();call execute_program(q,d)
        call require(d%code==2,'malformed public IR format rejected by runtime')
    end do
    call valid('(*(g0))',[ty_integer,ty_real,ty_character,ty_logical],.false.,'G0 intrinsic types without record reversion')
    call valid('(g0)',[ty_integer,ty_character],.true.,'ordinary G0 record reversion')
    call invalid('(g0)',[ty_integer,ty_integer],.false.,'internal normal reversion remains blocked')
    call valid('("p",*(2(g0,"s")))',[ty_integer,ty_character,ty_logical],.false.,'finite nesting inside unlimited')
    call valid('(*(g0))',[integer::],.false.,'empty list ends at first data descriptor')
    call valid('(*("p",g0,"s"))',[integer::],.false.,'empty prefix remains bounded')
    call invalid('(*("",1x))',[integer::],.false.,'unlimited needs data even with empty list')
    call invalid('(*(2("")))',[ty_integer],.false.,'nested no-data group')
    call invalid('(*(g0),i0)',[ty_integer],.true.,'unlimited must be final')
    call invalid('(2(*(g0)))',[ty_integer],.true.,'unlimited must be outer-level')
    call invalid('(*(g0),*(g0))',[ty_integer],.true.,'multiple unlimited groups')
    call invalid('(*(g0.5))',[ty_real],.true.,'bare G0 only')
    call invalid('(*(g0))',[ty_derived_base+1],.false.,'G0 excludes derived objects')
    call invalid('(*(g0))',[-1],.false.,'G0 excludes invalid negative type sentinel')
    call invalid('(*(g0))',[0],.false.,'G0 excludes missing type')
    call invalid('(*(g0))',[5],.false.,'G0 excludes unknown type')
    fmt='(*('//repeat('(',30)//'g0,g0'//repeat(')',30)//'))'
    call valid(fmt,[ty_integer,ty_integer],.false.,'64 format nodes including unlimited')
    fmt='(*('//repeat('(',30)//'g0,g0,g0'//repeat(')',30)//'))'
    call invalid(fmt,[ty_integer],.false.,'65 format nodes')
    fmt='(*('//repeat('(',31)//'g0'//repeat(')',31)//'))'
    call invalid(fmt,[ty_integer],.false.,'nesting depth remains31')
    allocate(types(65536),source=ty_character)
    call valid('(*(g0))',types,.false.,'exact expanded value cap')
    deallocate(types);allocate(types(65537),source=ty_character)
    call invalid('(*(g0))',types,.true.,'expanded value cap exceeded')
    deallocate(types);allocate(types(20000),source=ty_integer)
    call invalid('(*(10(""),i0))',types,.true.,'operation budget applies to unlimited traversal')
    d=diagnostic_t()
    call validate_print_format('(*(g0))',[ty_real],d,counts=[-1_int64],allow_reversion=.true.)
    call require(d%code==0,'dynamic shape may defer association')
    d=diagnostic_t()
    call validate_print_format('(*(10("")))',[ty_real],d,counts=[-1_int64],allow_reversion=.true.)
    call require(d%code/=0,'dynamic shape never bypasses no-data guard')
    d=diagnostic_t()
    call validate_print_format('(*(g0),i0)',[ty_real],d,counts=[-1_int64],allow_reversion=.true.)
    call require(d%code/=0,'dynamic shape never bypasses placement guard')
    print *,'PASS: unlimited/G0 native assertions:',checks
contains
    subroutine valid(fmt,types,revert,label)
        character(*),intent(in)::fmt,label
        integer,intent(in)::types(:)
        logical,intent(in)::revert
        d=diagnostic_t();call validate_print_format(fmt,types,d,allow_reversion=revert)
        call require(d%code==0,label)
    end subroutine
    subroutine invalid(fmt,types,revert,label)
        character(*),intent(in)::fmt,label
        integer,intent(in)::types(:)
        logical,intent(in)::revert
        d=diagnostic_t();call validate_print_format(fmt,types,d,allow_reversion=revert)
        call require(d%code/=0,label)
    end subroutine
    subroutine require(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        if(.not.ok)then
            print *,label
            if(allocated(d%message))print *,d%message
            error stop 'unlimited/G0 native assertion failed'
        end if
        checks=checks+1
    end subroutine
end program
