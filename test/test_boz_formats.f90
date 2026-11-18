! SPDX-License-Identifier: MIT
program test_boz_formats
 use, intrinsic::iso_fortran_env,only:int64
 use fi_ir
 use fi_parser,only:parse_subset
 use fi_frontend,only:verify_frontend
 use fi_runtime,only:execute_program,validate_print_format
 implicit none
 character(*),parameter::nl=new_line('a')
 character(*),parameter::source='program p'//nl//'implicit none'//nl// &
  'character(16)::s'//nl//'write(s,"(z8.8)")-1'//nl// &
  'if(s/="FFFFFFFF")error stop 1'//nl//'end program'
 character(50),parameter::good(*)=[character(50):: &
  '(b0)','(o0.0)','(z0.1024)','(b32.32)','(o22.22)','(z16.16)', &
  '(2(z8.4))','(*(b0,:))','(z8.8,t1,z4.4)','(b0,tl1,o0,tr1,z0)']
 character(70),parameter::bad(*)=[character(70):: &
  '(b)','(o)','(z)','(b4.)','(o2.3)','(z1.2)','(b-1)','(o0.-1)', &
  '(b1025)','(z0.1025)','(o99999999999999999999999999999999)', &
  '(z8.2e3)','(0b1)','(65537z1)','(2(*(z0)))','(*(z0),b1)', &
  '(b8,)', '(*(""))']
 type(program_t)::p,q
 type(diagnostic_t)::d
 character(:),allocatable::text
 integer::j,k,wr,checks
 checks=0
 do j=1,size(good)
  d=diagnostic_t();call validate_print_format(trim(good(j)),[ty_integer],d,4,1,allow_reversion=.true.)
  call require(d%code==0,'BOZ grammar accepts INTEGER')
  do k=ty_real,ty_character
   d=diagnostic_t();call validate_print_format(trim(good(j)),[k],d,4,1,allow_reversion=.true.)
   call require(d%code/=0,'BOZ rejects non-INTEGER effective item')
  end do
  d=diagnostic_t();call validate_print_format(trim(good(j)),[integer::],d,4,1,allow_reversion=.true.)
  call require(d%code==0,'valid BOZ format accepts empty list')
 end do
 do j=1,size(bad)
  d=diagnostic_t();call validate_print_format(trim(bad(j)),[integer::],d,4,1)
  call require(d%code/=0,'malformed BOZ rejected even empty')
  d=diagnostic_t();call validate_print_format(trim(bad(j)),[ty_integer],d,4,1,counts=[-1_int64])
  call require(d%code/=0,'dynamic count cannot bypass syntax')
 end do
 d=diagnostic_t();call parse_subset(source,p,d);call require(d%code==0,'source parse')
 d=diagnostic_t();call verify_frontend(source,p,d);call require(d%code==0,'source producer adapter')
 d=diagnostic_t();call execute_program(p,d);call require(d%code==0,'negative INTEGER4 has eight hex digits')
 wr=0
 do j=1,p%nc
  if(p%code(j)%op==op_write_internal)wr=j
 end do
 call require(wr>0,'WRITE found')
 q=p;q%code(wr)%format='(b8.8)';d=diagnostic_t()
 call verify_frontend(source,q,d);call require(d%code/=0,'adapter binds exact format string')
 do j=1,size(bad)
  q=p;q%code(wr)%format=trim(bad(j));d=diagnostic_t()
  call execute_program(q,d);call require(d%code/=0,'runtime independently validates public format')
 end do
 q=p;q%code(wr)%format='(f8.2)';d=diagnostic_t()
 call execute_program(q,d);call require(d%code/=0,'public IR type mismatch rejected')
 text='program p'//nl//'implicit none'//nl//'character(16)::s'//nl// &
  'write(s,"(z8.8)")1'//nl//'end program'
 d=diagnostic_t();call parse_subset(text,p,d);call require(d%code==0,'literal metadata baseline parse')
 d=diagnostic_t();call verify_frontend(text,p,d);call require(d%code==0,'literal metadata baseline adapter')
 do j=1,4
  q=p
  do k=1,q%ne
   if(q%expressions(k)%kind/=ex_literal.or.q%expressions(k)%typ/=ty_integer)cycle
   if(q%expressions(k)%value%i/=1)cycle
   select case(j)
   case(1);q%expressions(k)%real_kind=16;q%expressions(k)%value%real_kind=16
   case(2);q%expressions(k)%value%i=2147483648_int64
   case(3);q%expressions(k)%value%tag=ty_real
   case(4);q%expressions(k)%value%real_kind=8
   end select
   exit
  end do
  d=diagnostic_t();call execute_program(q,d);call require(d%code/=0,'malformed public INTEGER metadata rejected')
  if(j==4)call require(d%message=='output INTEGER value metadata differs from expression', &
   'declared/value kind mismatch fails before output')
 end do
 text='program p'//nl//'implicit none'//nl//'integer::i'//nl//'character(16)::s'//nl// &
  'write(s,"(*(z2.2))")(1,i=1,2)'//nl//'end program'
 d=diagnostic_t();call parse_subset(text,p,d);call require(d%code==0,'implied output baseline parse')
 d=diagnostic_t();call verify_frontend(text,p,d);call require(d%code==0,'implied output baseline adapter')
 d=diagnostic_t();call execute_program(p,d);call require(d%code==0,'implied output baseline run')
 do j=1,p%ne
  if(p%expressions(j)%kind/=ex_output_do)cycle
  k=p%expressions(j)%args(1);q=p;q%expressions(k)%value%real_kind=8
  d=diagnostic_t();call execute_program(q,d)
  call require(d%code/=0,'implied output INTEGER metadata guard')
  call require(d%message=='output INTEGER value metadata differs from expression','implied leaf kind exact guard')
  exit
 end do
 call run_case('integer(8)::n'//nl// &
  'n=-huge(0_8)'//nl//'n=n-1_8'//nl//'write(s,"(z0.0)")n', &
  '8000000000000000','machine-minimum nonzero hex field')
 call run_case('integer(8)::n'//nl// &
  'n=-huge(0_8)'//nl//'n=n-1_8'//nl//'write(s,"(o0.0)")n', &
  '1000000000000000000000','machine-minimum nonzero octal field')
 call run_case('integer::n'//nl//'n=-1'//nl//'write(s,"(b32.32)")n', &
  repeat('1',32),'INTEGER4 binary excludes host sign extension')
 call run_case('integer(8)::n'//nl//'n=-1_8'//nl//'write(s,"(b64.64)")n', &
  repeat('1',64),'INTEGER8 full binary field')
 call run_case('write(s,"(a,z0.0,a)")"[",0,"]"','[ ]','zero w=m produces one blank')
 call run_case('write(s,"(a,z4.0,a)")"[",0,"]"','[    ]','zero minimum blanks width')
 call run_case('write(s,"(a,z0.4,a)")"[",1,"]"','[0001]','minimum digits pad zeros')
 call run_case('write(s,"(z3)")-1','***','overflow asterisks')
 call run_case('write(s,"(a,t3,z2.2)")"ABCDEFGH",15','AB0FEFGH','backward overwrite suffix')
 print '(a,i0)','PASS BOZ assertions: ',checks
 contains
 subroutine run_case(body,expected,label)
  character(*),intent(in)::body,expected,label
  text='program p'//nl//'implicit none'//nl//'character(80)::s'//nl// &
   body//nl//'if(s/="'//expected//'")error stop 1'//nl//'end program'
  d=diagnostic_t();call parse_subset(text,q,d);call require(d%code==0,label//' parse')
  d=diagnostic_t();call verify_frontend(text,q,d);call require(d%code==0,label//' adapter')
  d=diagnostic_t();call execute_program(q,d);call require(d%code==0,label//' runtime')
 end subroutine
 subroutine require(ok,label)
  logical,intent(in)::ok
  character(*),intent(in)::label
  checks=checks+1
  if(.not.ok)then
   print '(a)',label
   if(allocated(d%message))print '(a)',d%message
   error stop 1
  end if
 end subroutine
end program
