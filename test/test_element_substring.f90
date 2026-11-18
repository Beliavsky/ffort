program test_element_substring
use fi_ir
use fi_parser,only:parse_subset
use fi_frontend,only:verify_frontend
use fi_runtime,only:execute_program
implicit none
type(program_t)::p
type(diagnostic_t)::d
character(*),parameter::nl=new_line('a')
character(:),allocatable::source
integer::mutation,e,root,b,s,checks,variant,a
checks=0
do variant=1,3
 source='implicit none'//nl//'character(4)::x(2)=["abcd","efgh"]'//nl
 select case(variant)
 case(1);source=source//'if(x(2)(2:3)/="fg")error stop "value"'//nl//'end'
 case(2);source=source//'if(kind(x(2)(2:3))/=1)error stop "kind"'//nl//'end'
 case(3);source=source//'x(2)(2:3)="PQ"'//nl//'if(x(2)/="ePQh")error stop "write"'//nl//'end'
 end select
 do mutation=0,18
  call parse_subset(source,p,d)
  call expect(d%code==0,'parse')
  root=0
  do e=1,p%ne
   if(p%expressions(e)%kind==ex_substring)root=e
  end do
  call expect(root>0,'substring root')
  b=p%expressions(root)%third;s=p%expressions(root)%symbol
  call expect(b>0,'element base')
  select case(mutation)
  case(1);p%expressions(root)%third=p%ne+1
  case(2);p%expressions(root)%third=root
  case(3);p%expressions(root)%rank=1
  case(4);p%expressions(root)%character_len=2
  case(5);p%expressions(root)%real_kind=8
  case(6);p%expressions(b)%kind=ex_variable
  case(7);p%expressions(b)%symbol=0
  case(8);p%expressions(b)%rank=1
  case(9);p%expressions(b)%dims(1)=1
  case(10);p%expressions(b)%real_kind=8
  case(11);p%expressions(b)%character_len=3
  case(12);p%expressions(b)%left=0
  case(13);p%expressions(b)%right=p%expressions(b)%left
  case(14);p%symbols(s)%real_kind=8
  case(15);a=p%expressions(b)%left;p%expressions(a)%dims(1)=1
  case(16);a=p%expressions(b)%left;p%expressions(a)%value%real_kind=8
  case(17);a=p%expressions(b)%left;p%expressions(a)%extent=1
  case(18);a=p%expressions(b)%left;p%expressions(a)%real_kind=3
  end select
  call verify_frontend(source,p,d)
  call expect((d%code==0).eqv.(mutation==0),'independent adapter')
  d=diagnostic_t()
  call execute_program(p,d)
  call expect((d%code==0).eqv.(mutation==0),'direct runtime')
 end do
end do
source='implicit none'//nl//'character(4),parameter::x(1)=["abcd"]'//nl// &
 'if(x(1)(2:3)/="bc")error stop "payload"'//nl//'end'
do mutation=0,6
 call parse_subset(source,p,d)
 call expect(d%code==0,'payload parse')
 s=0
 do e=1,p%ns
  if(p%symbols(e)%name=='x')s=e
 end do
 call expect(s>0,'payload symbol')
 select case(mutation)
 case(1);deallocate(p%symbols(s)%constant_values(1)%s)
 case(2);p%symbols(s)%constant_values(1)%tag=ty_integer
 case(3);p%symbols(s)%constant_values(1)%real_kind=8
 case(4);p%symbols(s)%constant_values(1)%s='abc'
 case(5);p%symbols(s)%constant_values(1)%s='abcde'
 case(6);allocate(p%symbols(s)%constant_values(1)%record)
 end select
 call execute_program(p,d)
 call expect((d%code==0).eqv.(mutation==0),'selected payload runtime')
end do
do variant=1,4
 source='module m'//nl//'contains'//nl//'subroutine show(text)'//nl// &
 'character(*),intent(in)::text'//nl//'end subroutine'//nl// &
 'integer function count_text(text)'//nl//'character(*),intent(in)::text'//nl// &
 'count_text=len(text)'//nl//'end function'//nl//'end module'//nl// &
 'use m'//nl//'implicit none'//nl//'character(4)::x(1)=["abcd"]'//nl
 select case(variant)
 case(1);source=source//'call show(x(1)(2:3))'//nl//'end'
 case(2);source=source//'call show((x(1)(2:3)))'//nl//'end'
 case(3);source=source//'if(count_text(text=x(1)(2:3))/=2)error stop "len"'//nl//'end'
 case(4);source=source//'if(count_text(text=(x(1)(2:3)))/=2)error stop "len"'//nl//'end'
 end select
 do mutation=0,1
  call parse_subset(source,p,d)
  call expect(d%code==0,'marker parse')
  root=0
  do e=1,p%ne
   if(p%expressions(e)%kind==ex_substring)root=e
  end do
  call expect(root>0,'marker root')
  if(mutation==1)p%expressions(root)%parenthesized=.not.p%expressions(root)%parenthesized
  call verify_frontend(source,p,d)
  call expect((d%code==0).eqv.(mutation==0),'source marker')
 end do
end do
source='implicit none'//nl//'integer,parameter::idx=1'//nl// &
 'character(4)::x(1)=["abcd"]'//nl//'if(kind(x(idx)(2:3))/=1)error stop "kind"'//nl//'end'
do mutation=0,2
 call parse_subset(source,p,d)
 call expect(d%code==0,'index cache parse')
 s=0
 do e=1,p%ns
  if(p%symbols(e)%name=='idx')s=e
 end do
 call expect(s>0,'index cache symbol')
 if(mutation==1)p%symbols(s)%constant_value%real_kind=8
 if(mutation==2)p%symbols(s)%constant_value%tag=ty_real
 call execute_program(p,d)
 call expect((d%code==0).eqv.(mutation==0),'metadata-only index cache runtime')
end do
print '(a,i0)','element substring assertions: ',checks
contains
subroutine expect(ok,message)
 logical,intent(in)::ok
 character(*),intent(in)::message
 if(.not.ok)then
  print *,message,variant,mutation,d%code,d%message
  error stop 'native assertion'
 end if
 checks=checks+1
end subroutine
end program
