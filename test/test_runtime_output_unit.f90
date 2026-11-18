! SPDX-License-Identifier: MIT
program test_runtime_output_unit
 use, intrinsic :: iso_fortran_env, only: output_unit,error_unit
 use fi_ir
 use fi_parser, only:parse_subset
 use fi_frontend, only:verify_frontend
 use fi_runtime, only:execute_program
 implicit none
 character(*),parameter::nl=new_line('a')
 character(*),parameter::source='program p'//nl//'use iso_fortran_env,only:output_unit'//nl// &
  'integer::u,v'//nl//'u=output_unit'//nl//'v=output_unit'//nl// &
  'write(u,"(a)",advance="no")""'//nl//'end program'
 type(program_t)::base,p
 type(diagnostic_t)::d
 integer::pc,e,s,j,which,checks,ios,other
 character::ch
 checks=0;which=0
 call parse_subset(source,base,d)
 call expect(d%code==0,'baseline parse')
 call verify_frontend(source,base,d)
 call expect(d%code==0,'baseline adapter')
 pc=0;other=0
 do j=1,base%nc
  if(base%code(j)%op==op_print)pc=j
 end do
 do j=1,base%ns
  if(base%symbols(j)%name=='v')other=j
 end do
 call expect(pc>0.and.other>0,'baseline identities')
 e=base%code(pc)%a;s=base%code(pc)%symbol
 call expect(valid_runtime_output_unit(base,e,s,0),'baseline public predicate')
 call reset_output();call execute_program(base,d)
 call expect(d%code==0,'baseline runtime')
 call empty_output()
 do which=1,61
  p=base
  select case(which)
  case(1);p%expressions(e)%kind=ex_literal
  case(2);p%expressions(e)%symbol=0
  case(3);p%expressions(e)%symbol=p%ns+1
  case(4);p%expressions(e)%scope=999
  case(5);p%expressions(e)%typ=ty_real
  case(6);p%expressions(e)%real_kind=2
  case(7);p%expressions(e)%rank=1
  case(8);p%expressions(e)%extent=1
  case(9);p%expressions(e)%dims(3)=1
  case(10);p%expressions(e)%parenthesized=.true.
  case(11);p%expressions(e)%character_len=0
  case(12);p%expressions(e)%length_expr=1
  case(13);p%expressions(e)%constructor_owner=1
  case(14);p%expressions(e)%constructor_kind_expr=1
  case(15);p%expressions(e)%generic_id=1
  case(16);p%expressions(e)%bound_type=1
  case(17);p%expressions(e)%bound_binding=1
  case(18);p%expressions(e)%intrinsic_mask=1
  case(19);p%expressions(e)%op='+'
  case(20);p%expressions(e)%left=1
  case(21);p%expressions(e)%right=1
  case(22);p%expressions(e)%stride=1
  case(23);p%expressions(e)%left2=1
  case(24);p%expressions(e)%right2=1
  case(25);p%expressions(e)%stride2=1
  case(26);p%expressions(e)%left3=1
  case(27);p%expressions(e)%right3=1
  case(28);p%expressions(e)%stride3=1
  case(29);p%expressions(e)%third=1
  case(30);allocate(p%expressions(e)%args(0))
  case(31);p%expressions(e)%triplet(2)=.true.
  case(32);p%expressions(e)%value%tag=ty_integer
  case(33);p%expressions(e)%value%i=1
  case(34);p%expressions(e)%value%r=1
  case(35);p%expressions(e)%value%l=.true.
  case(36);p%expressions(e)%value%real_kind=8
  case(37);p%expressions(e)%value%s='x'
  case(38);allocate(p%expressions(e)%value%record)
  case(39);p%symbols(s)%typ=ty_real
  case(40);p%symbols(s)%real_kind=8
  case(41);p%symbols(s)%rank=1
  case(42);p%symbols(s)%is_allocatable=.true.
  case(43);p%symbols(s)%is_pointer=.true.
  case(44);p%symbols(s)%is_class=.true.
  case(45);p%symbols(s)%is_intrinsic=.true.
  case(46);p%symbols(s)%intrinsic_import='output_unit'
  case(47);p%symbols(s)%deferred_character=.true.
  case(48);p%symbols(s)%character_len=0
  case(49);p%symbols(s)%length_expr=1
  case(50);p%symbols(s)%assumed_shape=.true.
  case(51);p%symbols(s)%is_automatic=.true.
  case(52);p%symbols(s)%scope=999
  case(53);p%symbols(s)%lower_expr=1
  case(54);p%symbols(s)%upper_expr=1
  case(55);p%symbols(s)%lower_expr2=1
  case(56);p%symbols(s)%upper_expr2=1
  case(57);p%symbols(s)%lower_expr3=1
  case(58);p%symbols(s)%upper_expr3=1
  case(59);p%symbols(s)%dummy_intent=4
  case(60);p%symbols(s)%is_dummy=.true.
  case(61);p%symbols(s)%is_optional=.true.
  end select
  call expect(.not.valid_runtime_output_unit(p,e,s,0),'public descriptor rejects mutant')
  d=diagnostic_t();call verify_frontend(source,p,d)
  call expect(d%code/=0,'adapter rejects descriptor mutant')
  d=diagnostic_t();call reset_output();call execute_program(p,d)
  call expect(d%code/=0,'runtime rejects descriptor mutant')
  call empty_output()
 end do
 do which=1,15
  p=base
  select case(which)
  case(1);p%code(pc)%a=0
  case(2);p%code(pc)%a=-1
  case(3);p%code(pc)%a=p%ne+1
  case(4);p%code(pc)%symbol=0
  case(5);p%code(pc)%symbol=p%ns+1
  case(6);p%code(pc)%b=1
  case(7);p%code(pc)%c=1
  case(8);p%code(pc)%d=1
  case(9);p%code(pc)%third=1
  case(10);p%code(pc)%target=1
  case(11);p%code(pc)%component=1
  case(12);p%code(pc)%generic_id=1
  case(13);p%code(pc)%bound_type=1
  case(14);p%code(pc)%bound_binding=1
  case(15);p%code(pc)%construct_name='bad'
  end select
  d=diagnostic_t();call verify_frontend(source,p,d)
  call expect(d%code/=0,'adapter rejects instruction mutant')
  d=diagnostic_t();call reset_output();call execute_program(p,d)
  call expect(d%code/=0,'runtime rejects instruction mutant')
  call empty_output()
 end do
 ! A different well-formed variable is safe IR, but cannot impersonate the
 ! source designator. Source binding is an independent adapter obligation.
 p=base;p%code(pc)%symbol=other;p%expressions(e)%symbol=other
 call expect(valid_runtime_output_unit(p,e,other,0),'different legal binding is structurally valid')
 d=diagnostic_t();call verify_frontend(source,p,d)
 call expect(d%code/=0,'source identity mismatch rejected')
 write(error_unit,'(a,i0)')'runtime output-unit checks: ',checks
contains
 subroutine reset_output()
  close(output_unit)
  open(unit=output_unit,status='scratch',action='readwrite',form='formatted')
 end subroutine
 subroutine empty_output()
  rewind(output_unit);read(output_unit,'(a)',iostat=ios)ch
  call expect(ios<0,'no output leaked')
 end subroutine
 subroutine expect(ok,label)
  logical,intent(in)::ok
  character(*),intent(in)::label
  checks=checks+1
  if(ok)return
  write(error_unit,*)'FAIL ',which,trim(label)
  if(allocated(d%message))write(error_unit,*)d%message
  error stop 1
 end subroutine
end program
