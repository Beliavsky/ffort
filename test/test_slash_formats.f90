! SPDX-License-Identifier: MIT
! Source-only draft. Execute only in the integrator's shared debug profile.
program test_slash_formats
 use, intrinsic::iso_fortran_env,only:int64,error_unit
 use fi_ir
 use fi_parser,only:parse_subset
 use fi_frontend,only:verify_frontend
 use fi_runtime,only:execute_program,validate_print_format
 implicit none
 character(*),parameter::nl=new_line('a')
 character(*),parameter::source='program p'//nl//'implicit none'//nl// &
  'character(4)::s'//nl//"write(s,'(a,:,/)')'X'"//nl// &
  "if(s/='X   ')error stop 1"//nl//'end program'
 character(80),parameter::good(*)=[character(80):: &
  '(i0,/,i0)','(i0//i0)','(/i0/i0)','(2(i0/))','(*(i0,/))', &
  '(i0,:,/)','(i0,/,t2,i0)','(i0,2/,i0)','(i0,:/,i0)']
 character(80),parameter::bad(*)=[character(80):: &
  '(0/)','(-1/)','(65537/)','(2147483647/)','(*( /))','(/,)', &
  '(2:)','(1.0/)','(999999999999999999999999999999999999/)', &
  '(2(*(i0,/)))']
 type(program_t)::p,q
 type(diagnostic_t)::d
 integer::j,k,wr,checks
 checks=0
 do j=1,size(good)
  d=diagnostic_t()
  call validate_print_format(trim(good(j)),[ty_integer,ty_integer],d,4,1,allow_reversion=.true.)
  call require(d%code==0,'valid external slash grammar/type association')
 end do
 do j=1,size(bad)
  d=diagnostic_t();call validate_print_format(trim(bad(j)),[integer::],d,4,1,allow_reversion=.true.)
  call require(d%code/=0,'malformed slash grammar rejected')
  d=diagnostic_t();call validate_print_format(trim(bad(j)),[ty_integer],d,4,1, &
   counts=[-1_int64],allow_reversion=.true.)
  call require(d%code/=0,'dynamic extent does not bypass syntax')
 end do
 d=diagnostic_t();call validate_print_format('(65536/)',[integer::],d,allow_reversion=.true.)
 call require(d%code==0,'full renderer buffer excludes final host record terminator')
 d=diagnostic_t();call validate_print_format('(i0,:,/)',[ty_integer],d)
 call require(d%code==0,'scalar internal colon skips slash')
 d=diagnostic_t();call validate_print_format('(i0,i0,/)',[ty_integer],d)
 call require(d%code==0,'exhausted data edit skips following slash')
 d=diagnostic_t();call validate_print_format('(:,/)',[integer::],d)
 call require(d%code==0,'empty-list colon skips slash')
 d=diagnostic_t();call validate_print_format('(i0,/)',[ty_integer],d)
 call require(d%code/=0,'reached scalar internal slash rejected')
 d=diagnostic_t();call validate_print_format('(/)',[integer::],d)
 call require(d%code/=0,'empty internal list still reaches slash')
 d=diagnostic_t();call validate_print_format('(i0,/,i0)',[ty_integer,ty_integer],d)
 call require(d%code/=0,'scalar internal record cannot advance for next item')
 d=diagnostic_t();call validate_print_format('(65536(t1),65536(t1),65536(t1),65536(t1),/)', &
  [integer::],d,allow_reversion=.true.)
 call require(d%code/=0,'format traversal budget is bounded')
 if(allocated(d%message))call require(index(d%message,'operation limit')>0,'reachable operation cap diagnostic')
 d=diagnostic_t();call parse_subset(source,p,d);call require(d%code==0,'internal colon baseline parse')
 d=diagnostic_t();call verify_frontend(source,p,d);call require(d%code==0,'producer format identity preserved')
 d=diagnostic_t();call execute_program(p,d);call require(d%code==0,'colon-skipped internal slash executes')
 wr=0
 do k=1,p%nc
  if(p%code(k)%op==op_write_internal)wr=k
 end do
 call require(wr>0,'internal output instruction identified')
 q=p;q%code(wr)%format='(a,/)';d=diagnostic_t()
 call verify_frontend(source,q,d);call require(d%code/=0,'adapter rejects substituted literal format')
 d=diagnostic_t();call execute_program(q,d)
 call require(d%code/=0,'source-free reached internal slash fails safely')
 q=p;q%code(wr)%format='(a,a,/)';d=diagnostic_t();call execute_program(q,d)
 call require(d%code==0,'source-free list exhaustion avoids unreached slash')
 do j=1,size(bad)
  q=p;q%code(wr)%format=trim(bad(j));d=diagnostic_t();call execute_program(q,d)
  call require(d%code/=0,'source-free malformed format fails independently')
 end do
 write(error_unit,'(a,i0)')'slash format assertions: ',checks
contains
 subroutine require(ok,label)
  logical,intent(in)::ok
  character(*),intent(in)::label
  checks=checks+1
  if(ok)return
  write(error_unit,'(a)')label
  if(allocated(d%message))write(error_unit,'(a)')d%message
  error stop 1
 end subroutine
end program
