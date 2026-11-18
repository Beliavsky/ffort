! SPDX-License-Identifier: MIT
program test_position_formats
 use fi_ir
 use fi_parser,only:parse_subset
 use fi_frontend,only:verify_frontend
 use fi_runtime,only:execute_program,validate_print_format
 implicit none
 character(*),parameter::nl=new_line('a')
 character(*),parameter::source='program p'//nl//'implicit none'//nl// &
  'character(8)::s'//nl//'write(s,"(a,t2,a)")"ABCD","x"'//nl// &
  'if(s/="AxCD")error stop 1'//nl//'end program'
 character(100),parameter::bad(*)=[character(100):: &
  '(t)','(tl)','(tr)','(t0)','(tl0)','(tr0)','(t-1)','(t1.0)', &
  '(2t1)','(1tl1)','(2tr1)','(t65537)','(tl65537)','(tr65537)', &
  '(t999999999999999999999999999999999999999999)','(*(t1,tl1,tr1))']
 character(40),parameter::good(*)=[character(40):: &
  '(a,t2,a)','(a,tl1,a)','(a,tr1,a)','(a,t65536,a)','(a,tl65536,a)', &
  '(a,tr65536,a)','(a,2(t1,a))','(*(a,t1,a))','(a,t2,a,:)']
 type(program_t)::p,q
 type(diagnostic_t)::d
 integer::j,k,wr,checks
 checks=0
 do j=1,size(good)
  d=diagnostic_t();call validate_print_format(trim(good(j)),[ty_character,ty_character],d,4,1,allow_reversion=.true.)
  call require(d%code==0,'valid grammar/type association')
 end do
 do j=1,size(bad)
  d=diagnostic_t();call validate_print_format(trim(bad(j)),[integer::],d,4,1)
  call require(d%code/=0,'invalid format rejected without values')
 end do
 d=diagnostic_t();call parse_subset(source,p,d);call require(d%code==0,'parse backward overwrite')
 d=diagnostic_t();call verify_frontend(source,p,d);call require(d%code==0,'producer/adapter preserved')
 d=diagnostic_t();call execute_program(p,d);call require(d%code==0,'runtime exact internal overwrite')
 wr=0
 do k=1,p%nc
  if(p%code(k)%op==op_write_internal)wr=k
 end do
 call require(wr>0,'internal WRITE identified')
 do j=1,size(bad)
  q=p;q%code(wr)%format=trim(bad(j));d=diagnostic_t()
  call execute_program(q,d);call require(d%code/=0,'public IR malformed format rejected')
 end do
 q=p;q%code(wr)%format='(tr65536,a,a)';d=diagnostic_t()
 call execute_program(q,d);call require(d%code/=0,'public IR position overflow rejected')
 q=p;q%code(wr)%format='(t65536,a,a)';d=diagnostic_t()
 call execute_program(q,d);call require(d%code/=0,'public IR target extent rejected')
 print '(a,i0)', 'PASS position format assertions: ',checks
 contains
 subroutine require(ok,description)
  logical,intent(in)::ok
  character(*),intent(in)::description
  checks=checks+1
  if(.not.ok)then
   print '(a)',description
   if(allocated(d%message))print '(a)',d%message
   error stop 1
  end if
 end subroutine
end program
