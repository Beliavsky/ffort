! SPDX-License-Identifier: MIT
program test_integer_masks
use,intrinsic::iso_fortran_env,only:int64
use fi_ir
use fi_parser,only:parse_subset
use fi_frontend,only:verify_frontend
use fi_runtime,only:execute_program,evaluate_constant
implicit none
character(*),parameter::nl=new_line('a')
character(8),parameter::names(3)=[character(8)::'maskl','maskr','shiftr']
type(program_t)::p
type(diagnostic_t)::d
type(value_t)::v
character(:),allocatable::source,expr,decl
integer::checks,name,form,mutation,e,a,b,s,j,k,n,q
integer(int64)::expected,remaining
checks=0
! All metadata guards also run below KIND and zero-sized outer expressions.
do name=1,3
 do form=1,3
  n=2;if(form==3)n=0
  decl='integer(8)::a('//itoa(n)//')'//nl//'a=1_8'//nl
  expr=trim(names(name))//'(a'
  if(name<=2)then
   expr=expr//',8)'
  else
   expr=expr//',1_4)'
  endif
  if(form==2)expr='kind('//expr//')'
  source='program p'//nl//'implicit none'//nl//decl//'print *,'//expr//nl//'end program'
  do mutation=0,43
   call parse_subset(source,p,d);call expect(d%code==0,'baseline parse')
   e=0
   do j=1,p%ne
    if(p%expressions(j)%op==trim(names(name)))e=j
   end do
   call expect(e>0,'intrinsic occurrence')
   a=p%expressions(e)%args(1);s=p%expressions(a)%symbol
   b=a;if(size(p%expressions(e)%args)==2)b=p%expressions(e)%args(2)
   select case(mutation)
   case(1);p%expressions(e)%typ=ty_real
   case(2);p%expressions(e)%real_kind=16
   case(3);p%expressions(e)%rank=4
   case(4);p%expressions(e)%extent=99
   case(5);p%expressions(e)%dims=[1_int64,2_int64,3_int64]
   case(6);p%expressions(e)%intrinsic_mask=1
   case(7);p%expressions(e)%args=[integer::]
   case(8);p%expressions(e)%args=[a,a,a]
   case(9);deallocate(p%expressions(e)%args)
   case(10);p%expressions(e)%args(1)=0
   case(11);p%expressions(e)%args(1)=p%ne+1
   case(12);p%expressions(e)%args(1)=e
   case(13);p%expressions(a)%typ=ty_real
   case(14);p%expressions(a)%real_kind=16
   case(15);p%expressions(a)%rank=4
   case(16);p%expressions(a)%extent=99
   case(17);p%expressions(a)%character_len=0
   case(18);p%expressions(e)%character_len=0
   case(19);p%expressions(e)%left=a
   case(20);p%expressions(e)%right=a
   case(21);p%expressions(e)%symbol=s
   case(22);p%expressions(e)%length_expr=a
   case(23);p%expressions(e)%constructor_kind_expr=a
   case(24);p%expressions(e)%triplet(2)=.true.
   case(25);p%expressions(e)%constructor_owner=1
   case(26);p%expressions(e)%generic_id=1
   case(27);p%expressions(e)%bound_type=1
   case(28);p%expressions(e)%bound_binding=1
   case(29);p%expressions(e)%stride2=a
   case(30);p%expressions(e)%left3=a
   case(31);p%expressions(e)%third=a
   case(32);p%expressions(a)%dims=[1_int64,0_int64,0_int64]
   case(33);p%expressions(b)%character_len=0
   case(34);p%symbols(s)%real_kind=4
   case(35);p%symbols(s)%typ=ty_real
   case(36);p%symbols(s)%rank=2
   case(37);p%expressions(e)%stride=a
   case(38);p%expressions(e)%right3=a
   case(39);p%expressions(e)%stride3=a
   case(40);p%expressions(e)%triplet(1)=.false.
   case(41);p%expressions(a)%extent=-2_int64
   case(42);p%expressions(e)%real_kind=4
   case(43);p%expressions(a)%real_kind=4
   end select
   call verify_frontend(source,p,d)
   call expect((d%code==0).eqv.(mutation==0),'adapter metadata guard')
   d=diagnostic_t();call execute_program(p,d,max_steps=20000_int64)
   call expect((d%code==0).eqv.(mutation==0),'runtime metadata guard')
   k=p%ne+1;p%ne=k;p%expressions(k)=expr_t(kind=ex_call,op='kind',typ=ty_integer,args=[e])
   d=diagnostic_t();call evaluate_constant(p,k,v,d)
   call expect((d%code==0).eqv.(mutation==0),'KIND metadata guard')
   if(mutation==0)then
    q=8
    call expect(v%i==q,'result kind')
   end if
  end do
 end do
end do
! Independent integer-only masks oracle. No host MASKL/MASKR/SHIFTR
! or floating-point conversion participates in expected values.
do name=1,2
 do q=4,8,4
  do n=0,8*q
   expr=trim(names(name))//'('//itoa(n)//'_8,'//itoa(q)//')'
   if(name==1)then
    if(n==0)then
     expected=0
    else if(q==8.and.n==1)then
     expected=-huge(0_int64)-1_int64
    else
     expected=-(2_int64**(8*q-n))
    endif
   else
    if(n==8*q)then
     expected=-1
    else if(n==63)then
     expected=huge(0_int64)
    else
     expected=2_int64**n-1_int64
    endif
   endif
   call value_oracle(expr,q,expected)
  enddo
 enddo
enddo
! Default MASK result is INTEGER(4), independent of a kind-8 I.
call value_oracle('maskl(1_8)',4,-2147483648_int64)
call value_oracle('maskr(1_8)',4,1_int64)
! Independent closed forms for signed endpoints and all shift counts.
do q=4,8,4
 do a=1,5
  select case(a)
  case(1)
   expr='(-huge(0_'//itoa(q)//')-1_'//itoa(q)//')'
   if(q==8)then
    remaining=-huge(0_int64)-1_int64
   else
    remaining=-2147483648_int64
   endif
  case(2);expr='-1_'//itoa(q);remaining=-1
  case(3);expr='0_'//itoa(q);remaining=0
  case(4);expr='1_'//itoa(q);remaining=1
  case(5)
   expr='huge(0_'//itoa(q)//')'
   remaining=huge(0_int64)
   if(q==4)remaining=2147483647_int64
  end select
  do n=0,8*q
   if(n==0)then
    expected=remaining
   else if(n==8*q)then
    expected=0
   else
    select case(a)
    case(1);expected=2_int64**(8*q-1-n)
    case(2)
     if(8*q-n==63)then
      expected=huge(0_int64)
     else
      expected=2_int64**(8*q-n)-1_int64
     endif
    case(3,4);expected=0
    case(5)
     expected=remaining
     do b=1,n
      expected=expected/2_int64
     enddo
    end select
   endif
   call value_oracle('shiftr('//expr//','//itoa(n)//'_8)',q,expected)
  enddo
 enddo
enddo
! Result selector literal mutation must fail both ordinary and unevaluated
! contexts, even when the resulting array contains no elements.
do name=1,2
 do form=1,3
  n=2;if(form==3)n=0
  expr=trim(names(name))//'(a,8)'
  if(form==2)expr='kind('//expr//')'
  source='program p'//nl//'integer::a('//itoa(n)//')'//nl//'a=1'//nl//'print *,'//expr//nl//'end program'
  do mutation=1,7
   call parse_subset(source,p,d);call expect(d%code==0,'selector baseline')
   do j=1,p%ne
    if(p%expressions(j)%op==trim(names(name)))e=j
   enddo
   b=p%expressions(e)%args(2)
   select case(mutation)
   case(1);p%expressions(b)%value%i=4
   case(2);p%expressions(b)%value%i=16
   case(3);p%expressions(b)%value%real_kind=8
   case(4);p%expressions(b)%rank=1;p%expressions(b)%extent=1
   case(5);p%expressions(b)%typ=ty_real
   case(6);p%expressions(b)%kind=ex_unary;p%expressions(b)%op='+';p%expressions(b)%left=b
   case(7);p%expressions(e)%real_kind=4
   end select
   call verify_frontend(source,p,d);call expect(d%code/=0,'selector adapter guard')
   d=diagnostic_t();call execute_program(p,d,max_steps=20000_int64)
   call expect(d%code/=0,'selector runtime guard')
   k=p%ne+1;p%ne=k;p%expressions(k)=expr_t(kind=ex_call,op='kind',typ=ty_integer,args=[e])
   d=diagnostic_t();call evaluate_constant(p,k,v,d)
   call expect(d%code/=0,'selector KIND guard')
  enddo
 enddo
enddo
! A selector PARAMETER cannot be replaced by a runtime value or stale cache.
do name=1,2
 do form=1,3
  n=2;if(form==3)n=0
  expr=trim(names(name))//'(a,kk)'
  if(form==2)expr='kind('//expr//')'
  source='program p'//nl//'integer,parameter::kk=8'//nl// &
   'integer::a('//itoa(n)//')'//nl//'a=1'//nl//'print *,'//expr//nl//'end program'
  do mutation=0,4
   call parse_subset(source,p,d);call expect(d%code==0,'parameter selector baseline')
   do j=1,p%ne
    if(p%expressions(j)%op==trim(names(name)))e=j
   enddo
   b=p%expressions(e)%args(2);s=p%expressions(b)%symbol
   call expect(s>0,'parameter selector symbol')
   select case(mutation)
   case(1);p%symbols(s)%is_parameter=.false.
   case(2);p%symbols(s)%parameter_ready=.false.
   case(3);p%symbols(s)%constant_value%i=4
   case(4);p%symbols(s)%constant_value%real_kind=8
   end select
   call verify_frontend(source,p,d)
   call expect((d%code==0).eqv.(mutation==0),'parameter selector adapter guard')
   d=diagnostic_t();call execute_program(p,d,max_steps=20000_int64)
   call expect((d%code==0).eqv.(mutation==0),'parameter selector runtime guard')
   k=p%ne+1;p%ne=k;p%expressions(k)=expr_t(kind=ex_call,op='kind',typ=ty_integer,args=[e])
   d=diagnostic_t();call evaluate_constant(p,k,v,d)
   call expect((d%code==0).eqv.(mutation==0),'parameter selector KIND guard')
  enddo
 enddo
enddo
write(*,'(a,i0,a)')'PASS: ',checks,' MASKL/MASKR/SHIFTR public-IR and independent-value checks'
contains
subroutine value_oracle(expression,wanted_kind,wanted)
character(*),intent(in)::expression
integer,intent(in)::wanted_kind
integer(int64),intent(in)::wanted
integer::idx,ii
source='program p'//nl//'print *,'//expression//nl//'end program'
call parse_subset(source,p,d);call expect(d%code==0,'oracle parse')
call verify_frontend(source,p,d);call expect(d%code==0,'oracle adapter')
idx=0
do ii=1,p%ne
 if(p%expressions(ii)%op=='maskl'.or.p%expressions(ii)%op=='maskr'.or.p%expressions(ii)%op=='shiftr')idx=ii
enddo
call expect(idx>0,'oracle occurrence')
call evaluate_constant(p,idx,v,d);call expect(d%code==0,'oracle evaluate')
call expect(v%tag==ty_integer.and.v%real_kind==wanted_kind.and.v%i==wanted,'independent exact value and kind')
end subroutine
subroutine expect(condition,label)
logical,intent(in)::condition
character(*),intent(in)::label
if(.not.condition)then
 print *,trim(label),d%code
 if(allocated(d%message))print *,d%message
 error stop 1
endif
checks=checks+1
end subroutine
function itoa(i) result(text)
integer,intent(in)::i
character(:),allocatable::text
character(40)::buffer
write(buffer,'(i0)')i
text=trim(buffer)
end function
end program
