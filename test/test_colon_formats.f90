! SPDX-License-Identifier: MIT
program test_colon_formats
    use, intrinsic::iso_fortran_env,only:int64
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program,validate_print_format
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program p'//nl//'implicit none'//nl// &
      'character(20)::s'//nl//'write(s,''(*(i0:,","))'')[1,2,3]'//nl// &
      'if(s/="1,2,3")error stop 1'//nl// &
      'write(s,''(i0:,3x,"BAD")'')1'//nl//'if(s/="1")error stop 2'//nl// &
      'write(s,''(:"BAD")'')'//nl//'if(s/="")error stop 3'//nl//'end program'
    type(program_t)::p,q
    type(diagnostic_t)::d
    integer::i,wr,k,checks
    integer,allocatable::types(:)
    character(:),allocatable::fmt
    checks=0
    call parse_subset(source,p,d);call require(d%code==0,'parse')
    call verify_frontend(source,p,d);call require(d%code==0,'source-bound adapter')
    call execute_program(p,d);call require(d%code==0,'internal colon output values')
    wr=0
    do i=1,p%nc
      if(p%code(i)%op==op_write_internal.and.wr==0)wr=i
    end do
    call require(wr>0,'internal write found')
    q=p;q%code(wr)%format='(*(i0,":"))'
    d=diagnostic_t();call verify_frontend(source,q,d);call require(d%code/=0,'colon/literal source identity')
    do k=1,10
      q=p
      select case(k)
      case(1);q%code(wr)%format='(2:)'
      case(2);q%code(wr)%format='(:0)'
      case(3);q%code(wr)%format='(:*)'
      case(4);q%code(wr)%format='(*(:))'
      case(5);q%code(wr)%format='(*(:,1x,""))'
      case(6);q%code(wr)%format='(*(i0:),a)'
      case(7);q%code(wr)%format='(i0:,a)'
      case(8);q%code(wr)%format='(i0:3x)'
      case(9);q%code(wr)%format='(65536(2("")),:)'
      case(10);q%code(wr)%format='('//repeat(':,',64)//'i0)'
      end select
      d=diagnostic_t();call execute_program(q,d);call require(d%code==2,'runtime format guards')
    end do
    call valid('(:)',[integer::],.false.,'only colon empty list')
    call valid('(:::) ',[integer::],.false.,'consecutive colons')
    call valid('(:"TAIL")',[integer::],.false.,'empty colon suppresses literal')
    call valid('(i0:,"TAIL")',[ty_integer],.false.,'colon suppresses tail')
    call valid('(i0:3x"TAIL")',[ty_integer],.false.,'not valid comma omission after X',.false.)
    call valid('(*(i0:,","))',[ty_integer,ty_integer],.false.,'unlimited same record')
    call valid('(i0:,",")',[ty_integer,ty_integer],.true.,'ordinary record reversion')
    call valid('(i0:,a)',[ty_integer],.false.,'exhausted list skips next data edit')
    call invalid('(i0:,a)',[ty_integer,ty_integer],.true.,'remaining data type checked')
    call invalid('(i0:,",")',[ty_integer,ty_integer],.false.,'internal ordinary reversion blocked')
    call invalid('(:"TAIL")',[ty_integer],.true.,'colon is not data edit')
    call invalid('(*(:))',[integer::],.false.,'empty unlimited colon is not data edit')
    call invalid('(*(:,"",1x))',[integer::],.false.,'unlimited no-data remains rejected')
    call invalid('(i0:,g0.5)',[ty_integer],.false.,'unreached malformed descriptor still rejected')
    fmt='('//repeat(':,',63)//'i0)'
    call valid(fmt,[ty_integer],.false.,'64 format nodes')
    fmt='('//repeat(':,',64)//'i0)'
    call invalid(fmt,[ty_integer],.false.,'65 format nodes')
    allocate(types(65536),source=ty_integer)
    call valid('(*(i0:))',types,.false.,'value cap and bounded unlimited iteration')
    deallocate(types);allocate(types(65537),source=ty_integer)
    call invalid('(*(i0:))',types,.true.,'value cap preserved')
    deallocate(types);allocate(types(20000),source=ty_integer)
    call invalid('(*(10(""),i0:))',types,.true.,'operation cap preserved')
    d=diagnostic_t();call validate_print_format('(*(i0:))',[ty_integer],d,counts=[-1_int64],allow_reversion=.true.)
    call require(d%code==0,'dynamic count defers association')
    d=diagnostic_t();call validate_print_format('(*(:))',[ty_integer],d,counts=[-1_int64],allow_reversion=.true.)
    call require(d%code/=0,'dynamic count never bypasses unlimited data guard')
    print *,'PASS: colon format native assertions:',checks
contains
    subroutine valid(fmt,types,revert,label,want)
      character(*),intent(in)::fmt,label
      integer,intent(in)::types(:)
      logical,intent(in)::revert
      logical,optional,intent(in)::want
      logical::ok
      ok=.true.;if(present(want))ok=want
      d=diagnostic_t();call validate_print_format(fmt,types,d,allow_reversion=revert)
      call require((d%code==0).eqv.ok,label)
    end subroutine
    subroutine invalid(fmt,types,revert,label)
      character(*),intent(in)::fmt,label
      integer,intent(in)::types(:)
      logical,intent(in)::revert
      call valid(fmt,types,revert,label,.false.)
    end subroutine
    subroutine require(ok,label)
      logical,intent(in)::ok
      character(*),intent(in)::label
      checks=checks+1
      if(ok)return
      print *,label
      if(allocated(d%message))print *,d%message
      error stop 1
    end subroutine
end program
