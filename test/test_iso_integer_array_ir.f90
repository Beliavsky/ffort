! SPDX-License-Identifier: MIT
program test_iso_integer_array_ir
use,intrinsic::iso_fortran_env,only:int64
use fi_ir
use fi_parser,only:parse_subset
use fi_frontend,only:verify_frontend
use fi_runtime,only:execute_program,evaluate_constant,evaluate_constant_array
implicit none
character(*),parameter::nl=new_line('a')
type(program_t)::p
type(diagnostic_t)::d
type(value_t)::v
type(value_t),allocatable::values(:)
character(:),allocatable::source,decl,expression,changed_source
integer::form,mutation,checks,e,s,target,index,j
checks=0
! Descriptor mutations must fail both adapter and runtime. Source/occurrence
! mutations test the independent adapter; runtime has no original source text.
do form=1,2
 if(form==1)then
  decl='integer::a';expression='ks(1)'
 else
  decl='integer::a(2)';expression='ks(2:1:-1)'
 endif
 source='program p'//nl//'use,intrinsic::iso_fortran_env,only:ks=>integer_kinds'//nl// &
  'implicit none'//nl//decl//nl//'a='//expression//nl//'end program'
 do mutation=0,14
  call parse_subset(source,p,d);call expect(d%code==0,'parse')
  s=0;target=0;e=0
  do j=1,p%ns
   if(p%symbols(j)%intrinsic_import=='integer_kinds')s=j
   if(p%symbols(j)%name=='a')target=j
  enddo
  do j=1,p%ne
   if(p%expressions(j)%symbol/=s)cycle
   if(form==1.and.p%expressions(j)%kind==ex_element)e=j
   if(form==2.and.p%expressions(j)%kind==ex_section)e=j
  enddo
  call expect(s>0.and.target>0.and.e>0,'exact array occurrence')
  index=p%expressions(e)%left
  select case(mutation)
  case(1);p%symbols(s)%real_kind=8
  case(2);p%symbols(s)%rank=2
  case(3);p%symbols(s)%intrinsic_import='real128'
  case(4);p%symbols(s)%constant_values(1)%i=9
  case(5);p%symbols(s)%constant_values(2)%real_kind=8
  case(6);p%symbols(s)%name='forged'
  case(7);p%symbols(s)%scope=123
  case(8);p%expressions(e)%symbol=target
  case(9);p%expressions(e)%rank=3
  case(10);p%expressions(e)%real_kind=8
  case(11);p%expressions(e)%typ=ty_real
  case(12);p%expressions(e)%left=0
  case(13);p%expressions(index)%value%i=p%expressions(index)%value%i+1
  case(14);p%expressions(index)%real_kind=8
  end select
  call verify_frontend(source,p,d)
  call expect((d%code==0).eqv.(mutation==0),'source/import/occurrence guard')
  if(mutation==0.or.(mutation>=1.and.mutation<=5).or.mutation==7)then
   d=diagnostic_t();call execute_program(p,d)
   call expect((d%code==0).eqv.(mutation==0),'immutable descriptor runtime guard')
  endif
  if(mutation==0)then
   d=diagnostic_t()
   if(form==1)then
    call evaluate_constant(p,e,v,d);call expect(d%code==0,'element constant')
    call expect(v%tag==ty_integer.and.v%real_kind==4.and.v%i==4,'independent first kind value')
   else
    call evaluate_constant_array(p,e,values,d);call expect(d%code==0,'section constant')
    call expect(size(values)==2,'section extent')
    call expect(all(values%tag==ty_integer).and.all(values%real_kind==4).and. &
     all(values%i==[8_int64,4_int64]),'independent reversed values')
   endif
  endif
 enddo
 call parse_subset(source,p,d);call expect(d%code==0,'source identity parse')
 call verify_frontend(source,p,d);call expect(d%code==0,'source identity baseline')
 changed_source='program p'//nl//'use,intrinsic::iso_fortran_env,only:other=>integer_kinds'//nl// &
  'implicit none'//nl//decl//nl//'a='//expression//nl//'end program'
 call verify_frontend(changed_source,p,d);call expect(d%code/=0,'source alias ownership mismatch')
enddo
write(*,'(a,i0)')'PASS: ISO indexed array public-IR assertions: ',checks
contains
subroutine expect(ok,label)
logical,intent(in)::ok
character(*),intent(in)::label
if(.not.ok)then
 print *,form,mutation,label,d%code
 if(allocated(d%message))print *,d%message
 error stop 1
endif
checks=checks+1
end subroutine
end program
