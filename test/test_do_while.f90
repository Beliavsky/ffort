program test_do_while
use, intrinsic :: iso_fortran_env, only:int64
use fi_ir
use fi_parser, only:parse_subset
use fi_frontend, only:verify_frontend
use fi_runtime, only:execute_program
implicit none
type(program_t)::p
type(diagnostic_t)::d
character(*),parameter::nl=new_line('a')
character(*),parameter::source='program p'//nl//'implicit none'//nl// &
'integer::i,n,j'//nl//'i=0'//nl//'n=0'//nl//'outer: do while(i<3)'//nl// &
'i=i+1'//nl//'do j=1,2'//nl//'n=n+1'//nl//'cycle outer'//nl// &
'end do'//nl//'end do outer'//nl//'j=5'//nl// &
'if(i/=3.or.n/=3.or.j/=5) error stop 1'//nl//'end program'
character(*),parameter::empty='implicit none'//nl//'do while(.true.)'//nl//'end do'//nl//'end'
character(*),parameter::logical_source='implicit none'//nl// &
'do while(.not.(.true.))'//nl//'error stop 1'//nl//'end do'//nl//'end'
character(*),parameter::char_source='implicit none'//nl// &
"do while('abc'=='xyz')"//nl//'error stop 1'//nl//'end do'//nl//'end'
character(*),parameter::param_source='implicit none'//nl// &
"character(3),parameter::s='abc'"//nl// &
"do while(s=='xyz')"//nl//'error stop 1'//nl//'end do'//nl//'end'
integer::which,phase,k,entry,back,cond,checks,child,symbol_index
integer(int64)::budget
checks=0
do phase=1,2
 do which=1,24
  if(phase==1.and.which>17) cycle
  call parse_subset(source,p,d)
  if(d%code/=0) error stop 'baseline parse'
  entry=0
  do k=1,p%nc
   if(p%code(k)%op==op_do.and.p%code(k)%d==2) entry=k
  end do
  if(entry==0) error stop 'missing DO WHILE'
  back=p%code(entry)%target-1;cond=p%code(entry)%a
  select case(which)
  case(2);p%code(entry)%d=3;p%code(back)%d=3
  case(3);p%code(entry)%d=1;p%code(back)%d=1
  case(4);p%code(entry)%a=0
  case(5);p%code(entry)%a=p%ne+1
  case(6);p%code(entry)%b=cond
  case(7);p%code(entry)%c=cond
  case(8);p%code(entry)%symbol=1;p%code(back)%symbol=1
  case(9);p%expressions(cond)%rank=1
  case(10);p%expressions(cond)%typ=ty_integer
  case(11);p%expressions(cond)%real_kind=8
  case(12);p%expressions(cond)%extent=1
  case(13);p%expressions(cond)%dims(1)=1
  case(14);p%expressions(cond)%character_len=1
  case(15);p%code(back)%d=1
  case(16);p%code(back)%target=entry
  case(17);p%code(entry)%target=entry
  case(18);p%expressions(p%expressions(cond)%right)%value%real_kind=8
  case(19);p%expressions(p%expressions(cond)%right)%value%tag=ty_logical
  case(20);p%expressions(p%expressions(cond)%right)%dims(1)=1
  case(21);p%expressions(p%expressions(cond)%right)%value%s='invalid'
  case(22);p%expressions(cond)%left=cond
  case(23);p%expressions(p%expressions(cond)%right)%rank=1
  case(24);p%expressions(p%expressions(cond)%left)%real_kind=8
  end select
  if(phase==1) then
   call verify_frontend(source,p,d)
  else
   call execute_program(p,d,max_steps=300_int64)
  end if
  if((which==1).neqv.(d%code==0)) then
   print *,phase,which,d%code,d%message
   error stop 'DO WHILE guard mismatch'
  end if
  checks=checks+1
 end do
end do
do which=0,4
 call parse_subset(empty,p,d);call verify_frontend(empty,p,d)
 if(d%code/=0) error stop 'empty while frontend'
 budget=int(which,int64)
 call execute_program(p,d,budget_remaining=budget)
 if(d%code/=2.or.budget/=0_int64) error stop 'wrong while budget outcome'
 if(index(d%message,'execution step limit exceeded')==0) error stop 'wrong budget diagnostic'
 checks=checks+1
end do
do which=1,5
 call parse_subset(logical_source,p,d)
 if(d%code/=0) error stop 'logical baseline parse'
 entry=1;cond=p%code(entry)%a;child=p%expressions(cond)%left
 if(child<1.or.child>p%ne) error stop 'missing logical child'
 select case(which)
 case(2);p%expressions(child)%value%real_kind=8
 case(3);p%expressions(child)%value%tag=ty_integer
 case(4);p%expressions(child)%real_kind=8
 case(5);p%expressions(child)%character_len=1
 end select
 call execute_program(p,d,max_steps=100_int64)
 if((which==1).neqv.(d%code==0)) error stop 'nested logical condition metadata bypass'
 checks=checks+1
end do
do phase=1,2
 do which=1,3
  if(phase==1) then
   call parse_subset(char_source,p,d)
  else
   call parse_subset(param_source,p,d)
  end if
  if(d%code/=0) error stop 'character baseline parse'
  entry=1;cond=p%code(entry)%a;child=p%expressions(cond)%left
  if(phase==1) then
   if(which==2) deallocate(p%expressions(child)%value%s)
   if(which==3) p%expressions(child)%value%s='bad length'
  else
   symbol_index=p%expressions(child)%symbol
   if(.not.p%symbols(symbol_index)%parameter_ready) error stop 'parameter cache not ready'
   if(which==2) deallocate(p%symbols(symbol_index)%constant_value%s)
   if(which==3) p%symbols(symbol_index)%constant_value%s='bad length'
  end if
  call execute_program(p,d,max_steps=100_int64)
  if((which==1).neqv.(d%code==0)) error stop 'nested character condition metadata bypass'
  checks=checks+1
 end do
end do
do which=1,3
 call parse_subset(logical_source,p,d)
 if(d%code/=0) error stop 'implicit mapping parse'
 if(which==2) p%end_line=p%end_line+1
 if(which==3) p%code(1)%line=p%code(1)%line+1
 call verify_frontend(logical_source,p,d)
 if((which==1).neqv.(d%code==0)) error stop 'implicit mapping guard'
 checks=checks+1
end do
print '(a,i0)','PASS DO WHILE guards: ',checks
end program
