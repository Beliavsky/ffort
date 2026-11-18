! SPDX-License-Identifier: MIT
program test_inquire_name
use, intrinsic :: iso_fortran_env, only:int64
use fi_ir
use fi_parser,only:parse_subset
use fi_frontend,only:verify_frontend
use fi_runtime,only:execute_program,input_unit_t,validate_input_units
implicit none
type(program_t)::p
type(diagnostic_t)::d
type(input_unit_t)::inputs(1)
character(*),parameter::nl=new_line('a'),file_name='input sample.dat'
character(:),allocatable::source,data_before,name_before
integer::mutation,checks,pc,j,ue,ne,us,ns,position_before
logical::endfile_before
checks=0
source='program p'//nl//'implicit none'//nl//'integer::iu'//nl//'character(24)::nm'//nl// &
 'iu=17'//nl//'nm="unchanged"'//nl//'inquire(unit=iu,name=nm)'//nl// &
 'if(nm/="input sample.dat        ")error stop "name"'//nl//'end program'
do mutation=0,44
 call parse_subset(source,p,d);call expect(d%code==0,'parse baseline')
 pc=0
 do j=1,p%nc
  if(p%code(j)%op==op_inquire_name)pc=j
 end do
 call expect(pc>0,'inquiry occurrence')
 ue=p%code(pc)%a;ne=p%code(pc)%b;us=p%expressions(ue)%symbol;ns=p%expressions(ne)%symbol
 select case(mutation)
 case(1);p%code(pc)%a=0
 case(2);p%code(pc)%b=0
 case(3);p%code(pc)%a=p%ne+1
 case(4);p%code(pc)%b=p%ne+1
 case(5);p%code(pc)%symbol=ns
 case(6);p%code(pc)%c=1
 case(7);p%code(pc)%d=1
 case(8);p%code(pc)%third=1
 case(9);p%code(pc)%target=1
 case(10);p%code(pc)%component=1
 case(11);p%code(pc)%generic_id=1
 case(12);p%code(pc)%bound_type=1
 case(13);p%code(pc)%bound_binding=1
 case(14);p%code(pc)%construct_name='wrong'
 case(15);p%code(pc)%format_expr=1
 case(16);p%code(pc)%advance_mode=1
 case(17);p%code(pc)%format='(a)'
 case(18);p%code(pc)%items=[integer::]
 case(19);p%code(pc)%scope=1
 case(20);p%expressions(ue)%typ=ty_real
 case(21);p%expressions(ue)%real_kind=8
 case(22);p%expressions(ue)%rank=1
 case(23);p%expressions(ue)%extent=1
 case(24);p%expressions(ue)%dims=[1_int64,0_int64,0_int64]
 case(25);p%expressions(ue)%parenthesized=.true.
 case(26);p%expressions(ue)%value%tag=ty_integer
 case(27);p%expressions(ue)%args=[integer::]
 case(28);p%expressions(ue)%left=1
 case(29);p%expressions(ue)%scope=1
 case(30);p%symbols(us)%is_parameter=.true.
 case(31);p%symbols(us)%real_kind=16
 case(32);p%expressions(ne)%typ=ty_integer
 case(33);p%expressions(ne)%real_kind=8
 case(34);p%expressions(ne)%rank=1
 case(35);p%expressions(ne)%extent=1
 case(36);p%expressions(ne)%parenthesized=.true.
 case(37);p%expressions(ne)%character_len=23
 case(38);p%symbols(ns)%is_parameter=.true.
 case(39);p%symbols(ns)%is_pointer=.true.
 case(40);p%symbols(ns)%is_class=.true.
 case(41);p%symbols(ns)%is_intrinsic=.true.
 case(42);p%symbols(ns)%dummy_intent=1
 case(43);p%symbols(ns)%scope=-1
 case(44);p%code(pc)%b=ue
 end select
 call verify_frontend(source,p,d)
 call expect((d%code==0).eqv.(mutation==0),'adapter contract')
 inputs(1)=input_unit_t(unit=17,data='alpha'//nl//'beta'//nl,name=file_name)
 data_before=inputs(1)%data;name_before=inputs(1)%name
 d=diagnostic_t();call execute_program(p,d,input_units=inputs)
 call expect((d%code==0).eqv.(mutation==0),'standalone runtime contract')
 call expect(inputs(1)%position==1.and..not.inputs(1)%endfile,'cursor unchanged')
 call expect(inputs(1)%data==data_before.and.inputs(1)%name==name_before,'registered bytes/name unchanged')
end do
! Input metadata failures occur before interpretation. The API remains optional-name
! compatible with old READ bindings, while NAME needs an explicit stored identity.
do mutation=0,8
 call parse_subset(source,p,d);call expect(d%code==0,'descriptor parse')
 inputs(1)=input_unit_t(unit=17,data='alpha'//nl,name=file_name)
 select case(mutation)
 case(1);deallocate(inputs(1)%name)
 case(2);inputs(1)%name=''
 case(3);inputs(1)%name=repeat('x',4097)
 case(4);inputs(1)%name='a'//achar(0)//'b'
 case(5);inputs(1)%unit=18
 case(6);inputs(1)%position=2
 case(7);inputs(1)%endfile=.true.
 case(8);deallocate(inputs(1)%data)
 end select
 position_before=inputs(1)%position;endfile_before=inputs(1)%endfile
 d=diagnostic_t();call execute_program(p,d,input_units=inputs)
 call expect((d%code==0).eqv.(mutation==0),'registered descriptor contract')
 call expect(inputs(1)%position==position_before.and.(inputs(1)%endfile.eqv.endfile_before),'failure leaves cursor/endfile')
end do
! A completed endfile state remains untouched by a successful metadata inquiry.
call parse_subset(source,p,d);call expect(d%code==0,'EOF inquiry parse')
inputs(1)=input_unit_t(unit=17,data='alpha'//nl,name=file_name)
inputs(1)%position=len(inputs(1)%data)+1;inputs(1)%endfile=.true.
call execute_program(p,d,input_units=inputs);call expect(d%code==0,'EOF inquiry')
call expect(inputs(1)%position==len(inputs(1)%data)+1.and.inputs(1)%endfile,'EOF state unchanged')
! Old unnamed registered input still works for external READ, never host stdin.
source='program p'//nl//'integer::iu'//nl//'character(5)::nm'//nl//'iu=17'//nl// &
 'read(iu,"(a)")nm'//nl//'if(nm/="alpha")error stop "read"'//nl//'end program'
call parse_subset(source,p,d);call expect(d%code==0,'old unnamed READ parse')
inputs(1)=input_unit_t(unit=17,data='alpha'//nl)
call validate_input_units(inputs,d);call expect(d%code==0,'old unnamed input valid')
call execute_program(p,d,input_units=inputs);call expect(d%code==0,'old unnamed READ execute')
! Procedure metadata and transitive call-stack restrictions remain independent.
source='module m'//nl//'contains'//nl//'subroutine q(iu,nm)'//nl// &
 'integer,intent(in)::iu'//nl//'character(*),intent(out)::nm'//nl// &
 'inquire(unit=iu,name=nm)'//nl//'end subroutine'//nl//'end module'//nl// &
 'program p'//nl//'use m'//nl//'integer::iu'//nl//'character(24)::nm'//nl// &
 'iu=17'//nl//'call q(iu,nm)'//nl// &
 'if(nm/="input sample.dat        ")error stop "name"'//nl//'end program'
do mutation=0,2
 call parse_subset(source,p,d);call expect(d%code==0,'effect baseline parse')
 call expect(p%np==1,'one inquiry subroutine')
 if(mutation==1)p%procedures(1)%is_pure=.true.
 if(mutation==2)p%procedures(1)%is_simple=.true.
 call verify_frontend(source,p,d);call expect((d%code==0).eqv.(mutation==0),'effect adapter')
 inputs(1)=input_unit_t(unit=17,data='alpha'//nl,name=file_name)
 d=diagnostic_t();call execute_program(p,d,input_units=inputs)
 call expect((d%code==0).eqv.(mutation==0),'effect runtime')
 call expect(inputs(1)%position==1.and..not.inputs(1)%endfile,'effect cursor unchanged')
end do
source='module m'//nl//'contains'//nl//'subroutine q(iu,nm)'//nl// &
 'integer,intent(in)::iu'//nl//'character(*),intent(out)::nm'//nl// &
 'inquire(unit=iu,name=nm)'//nl//'end subroutine'//nl// &
 'integer function f()'//nl//'integer::iu'//nl//'character(24)::nm'//nl// &
 'iu=17'//nl//'call q(iu,nm)'//nl//'f=1'//nl//'end function'//nl//'end module'//nl// &
 'program p'//nl//'use m'//nl//'integer::j'//nl//'j=f()'//nl//'end program'
call parse_subset(source,p,d);call expect(d%code==0,'transitive function parse')
call verify_frontend(source,p,d);call expect(d%code==0,'transitive source accepted before execution')
inputs(1)=input_unit_t(unit=17,data='alpha'//nl,name=file_name)
call execute_program(p,d,input_units=inputs);call expect(d%code/=0,'transitive ordinary function effect rejected')
call expect(inputs(1)%position==1.and..not.inputs(1)%endfile,'transitive failure cursor unchanged')
! Charge name copy/padding on the INQUIRE line before the output commit.
source='program p'//nl//'integer::iu'//nl//'character(1000)::nm'//nl// &
 'iu=17'//nl//'inquire(unit=iu,name=nm)'//nl//'end program'
call parse_subset(source,p,d);call expect(d%code==0,'budget parse')
inputs(1)=input_unit_t(unit=17,data='alpha'//nl,name=file_name)
call execute_program(p,d,max_steps=128_int64,input_units=inputs)
call expect(d%code/=0.and.d%line==5,'inquiry copy charged before commit')
call expect(inputs(1)%position==1.and..not.inputs(1)%endfile,'budget failure leaves input state')
print '(a,i0,a)','PASS: ',checks,' INQUIRE metadata/registration assertions'
contains
subroutine expect(ok,label)
logical,intent(in)::ok
character(*),intent(in)::label
checks=checks+1
if(ok)return
print *,mutation,label,d%code
if(allocated(d%message))print *,d%message
error stop 'INQUIRE assertion failed'
end subroutine
end program
