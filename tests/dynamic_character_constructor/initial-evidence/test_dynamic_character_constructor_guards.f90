! SPDX-License-Identifier: MIT
! Source-only independent public IR test. Build/link only after owner clearance.
program test_dynamic_character_constructor_guards
 use, intrinsic :: iso_fortran_env, only:error_unit
 use fi_ir
 use fi_parser, only:parse_subset
 use fi_runtime, only:execute_program
 implicit none
 character(*),parameter::nl=new_line('a')
 character(*),parameter::src='module m'//nl//'contains'//nl// &
 'subroutine f(x)'//nl//'character(*),intent(in)::x'//nl//'integer::i'//nl// &
 'character(len(x))::y(2)'//nl//'y=[(x,i=1,2)]'//nl// &
 'if(len(y)/=len(x).or.any(y/=x))stop 1'//nl//'end subroutine'//nl// &
 'end module'//nl//'program p'//nl//'use m'//nl// &
 "call f('a')"//nl//"call f('abcde')"//nl//"call f('')"//nl//'end program'
 type(program_t)::p,q
 type(diagnostic_t)::d
 integer::j,root,leaf,s,checks,k
 checks=0;root=0;leaf=0
 call parse_subset(src,p,d)
 call expect(d%code==0,'baseline parses')
 do j=1,p%ne
  if(p%expressions(j)%kind==ex_constructor.and.p%expressions(j)%typ==ty_character) root=j
  if(p%expressions(j)%kind==ex_variable.and.p%expressions(j)%typ==ty_character) then
   s=p%expressions(j)%symbol
   if(s>0.and.s<=p%ns) then
    if(p%symbols(s)%name=='x') leaf=j
   end if
  end if
 end do
 call expect(root>0.and.leaf>0,'dynamic constructor and descriptor leaf exist')
 s=p%expressions(leaf)%symbol
 call expect(valid_constructor_character_metadata(p,root),'baseline metadata valid')
 call expect(constructor_length_item_supported(p,leaf),'descriptor length supported')
 call execute_program(p,d)
 call expect(d%code==0,'length refreshes across three activations')
 d=diagnostic_t();call execute_program(p,d)
 call expect(d%code==0,'second independent execution refreshes all lengths')
 do k=1,4
  q=p
  select case(k)
  case(1);q%expressions(root)%character_len=0
  case(2);q%expressions(root)%character_len=5
  case(3);q%expressions(root)%character_len=-2
  case(4);q%expressions(root)%length_expr=leaf
  end select
  call expect(.not.valid_constructor_character_metadata(q,root),'forged constructor length rejected')
  d=diagnostic_t();call execute_program(q,d)
  call expect(d%code/=0,'runtime rejects forged constructor metadata')
 end do
 do k=1,9
  q=p
  select case(k)
  case(1);q%expressions(leaf)%symbol=0
  case(2);q%expressions(leaf)%symbol=p%ns+1
  case(3);q%symbols(s)%typ=ty_integer
  case(4);q%symbols(s)%character_len=5
  case(5);q%symbols(s)%is_pointer=.true.
  case(6);q%expressions(leaf)%kind=ex_call
  case(7);q%expressions(leaf)%kind=ex_binary;q%expressions(leaf)%op='//'; &
    q%expressions(leaf)%left=leaf;q%expressions(leaf)%right=leaf
  case(8);q%expressions(leaf)%character_len=-2
  case(9);q%expressions(leaf)%real_kind=8
  end select
  call expect(.not.constructor_length_item_supported(q,leaf),'bad descriptor/call/cycle rejected')
 end do
 call reject_runtime('program p'//nl//'character(:),allocatable::x'//nl//'integer::i'//nl// &
  'print *,len([(x,i=1,0)])'//nl//'end program','unallocated descriptor required for empty inquiry')
 call reject_runtime('module m'//nl//'contains'//nl//'subroutine f(x)'//nl// &
  'character(*),optional::x'//nl//'integer::i'//nl//'print *,len([(x,i=1,0)])'//nl// &
  'end subroutine'//nl//'end module'//nl//'program p'//nl//'use m'//nl//'call f()'//nl// &
  'end program','absent descriptor required for empty inquiry')
 write(*,'(a,i0)')'dynamic CHARACTER constructor guards: ',checks
contains
 subroutine expect(ok,label)
  logical,intent(in)::ok
  character(*),intent(in)::label
  if(.not.ok)then
   write(error_unit,'(a)')'FAIL: '//label
   stop 1
  endif
  checks=checks+1
 end subroutine
 subroutine reject_runtime(text,label)
  character(*),intent(in)::text,label
  type(program_t)::r
  type(diagnostic_t)::e
  call parse_subset(text,r,e)
  call expect(e%code==0,label//' parses')
  call execute_program(r,e)
  call expect(e%code/=0,label//' fails safely')
 end subroutine
end program
