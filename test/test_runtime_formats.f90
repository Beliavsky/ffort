! SPDX-License-Identifier: MIT
program test_runtime_formats
 use fi_ir
 use fi_parser,only:parse_subset
 use fi_frontend,only:verify_frontend
 use fi_runtime,only:execute_program
 use fortfront_compiler,only:compiler_frontend_result_t,compiler_frontend_options_t, &
  compile_frontend_from_string,INPUT_MODE_STANDARD,OPERATING_MODE_STRICT
 use ast_arena_modern,only:ast_arena_t
 use ast_factory_io,only:push_write_statement
 use ast_nodes_io,only:write_statement_node
 implicit none
 character(*),parameter::nl=new_line('a')
 character(*),parameter::source='program p'//nl//'implicit none'//nl// &
  'character(8)::fmt,other,s'//nl//'fmt="(i0)"'//nl//'other="(i0)"'//nl// &
  'write(unit=s,fmt=fmt)42'//nl//'if(s/="42")error stop 1'//nl//'end program'
 character(*),parameter::outs='program p'//nl//'write(*,"(a)",advance="no")"A"'//nl//'end program'
 character(*),parameter::prints='program p'//nl//'print "(a)","A"'//nl//'end program'
 type(ast_arena_t)::arena
 type(program_t)::p,q
 type(diagnostic_t)::d
 type(compiler_frontend_result_t)::front
 type(compiler_frontend_options_t)::opts
 integer::i,k,wr,e,s,other,checks,writes
 checks=0
 call parse_subset(source,p,d);call require(d%code==0,'parse dynamic internal WRITE')
 d=diagnostic_t();call verify_frontend(source,p,d);call require(d%code==0,'source binding verified')
 d=diagnostic_t();call execute_program(p,d);call require(d%code==0,'dynamic internal WRITE executes')
 opts%input_mode=INPUT_MODE_STANDARD;opts%operating_mode=OPERATING_MODE_STRICT
 call compile_frontend_from_string(source,front,opts);writes=0
 do i=1,front%arena%size
  if(.not.allocated(front%arena%entries(i)%node))cycle
  select type(node=>front%arena%entries(i)%node)
  type is(write_statement_node)
   writes=writes+1
   call require(node%is_formatted,'producer formatted flag')
   call require(node%format_spec=='fmt','producer name retained')
   call require(node%format_expr_index==0,'whole name uses canonical format_spec')
   call require(size(node%specifiers)==2,'two controls')
   call require(node%specifiers(1)%name=='unit'.and.node%specifiers(2)%name=='fmt','control names')
  end select
 end do
 call require(writes==1,'one WRITE producer')
 do k=1,7
  select case(k)
  case(1);i=push_write_statement(arena,'6')
  case(2);i=push_write_statement(arena,'6',format_spec='')
  case(3);i=push_write_statement(arena,'*',format_spec='*')
  case(4);i=push_write_statement(arena,'*',format_spec='(i0)')
  case(5);i=push_write_statement(arena,'*',format_spec='fmt')
  case(6);i=push_write_statement(arena,'*',format_expr_index=1)
  case(7);i=push_write_statement(arena,'*',namelist_group='group')
  end select
  select type(node=>arena%entries(i)%node)
  type is(write_statement_node)
   call require(node%is_formatted.eqv.(k>=3),'factory formatted and unformatted paths')
  class default
   error stop 'WRITE factory returned wrong type'
  end select
 end do
 wr=0;other=0
 do i=1,p%nc
  if(p%code(i)%op==op_write_internal)wr=i
 end do
 e=p%code(wr)%format_expr;s=p%expressions(e)%symbol
 do i=1,p%ns
  if(trim(p%symbols(i)%name)=='other')other=i
 end do
 call require(e>0.and.other>0,'format and alternate symbol found')
 do k=1,37
  q=p
  select case(k)
  case(1);q%code(wr)%format_expr=-1
  case(2);q%code(wr)%format_expr=p%ne+1
  case(3);q%code(wr)%format='(i0)'
  case(4);q%code(wr)%format_expr=0
  case(5);q%code(wr)%advance_mode=1
  case(6);q%code(wr)%advance_mode=2
  case(7);q%expressions(e)%kind=ex_literal
  case(8);q%expressions(e)%typ=ty_integer
  case(9);q%expressions(e)%real_kind=8
  case(10);q%expressions(e)%rank=1
  case(11);q%expressions(e)%extent=1
  case(12);q%expressions(e)%dims(3)=1
  case(13);q%expressions(e)%character_len=7
  case(14);q%expressions(e)%scope=99
  case(15);q%expressions(e)%left=e
  case(16);q%expressions(e)%right=e
  case(17);q%expressions(e)%stride=e
  case(18);q%expressions(e)%left2=e
  case(19);q%expressions(e)%right2=e
  case(20);q%expressions(e)%stride2=e
  case(21);q%expressions(e)%left3=e
  case(22);q%expressions(e)%right3=e
  case(23);q%expressions(e)%stride3=e
  case(24);q%expressions(e)%third=e
  case(25);q%expressions(e)%length_expr=e
  case(26);q%expressions(e)%generic_id=1
  case(27);q%expressions(e)%bound_type=1
  case(28);q%expressions(e)%bound_binding=1
  case(29);q%expressions(e)%intrinsic_mask=1
  case(30);q%expressions(e)%op='x'
  case(31);allocate(q%expressions(e)%args(0))
  case(32);q%expressions(e)%constructor_kind_expr=e
  case(33);q%expressions(e)%parenthesized=.true.
  case(34);q%expressions(e)%triplet(2)=.true.
  case(35);q%expressions(e)%symbol=0
  case(36);q%expressions(e)%symbol=p%ns+1
  case(37);q%symbols(s)%is_parameter=.true.
  end select
  d=diagnostic_t();call verify_frontend(source,q,d);call require(d%code/=0,'adapter rejects format mutation')
  d=diagnostic_t();call execute_program(q,d);call require(d%code==2,'runtime rejects format mutation')
 end do
 q=p;q%expressions(e)%symbol=other
 d=diagnostic_t();call verify_frontend(source,q,d);call require(d%code/=0,'coherent alternate symbol rejected by source identity')
 q=p;q%code(1)%format_expr=e
 d=diagnostic_t();call verify_frontend(source,q,d);call require(d%code/=0,'adapter rejects format on assignment')
 d=diagnostic_t();call execute_program(q,d);call require(d%code==2,'runtime rejects format on assignment')
 call parse_subset(outs,p,d);call require(d%code==0,'nonadvancing source parse')
 d=diagnostic_t();call verify_frontend(outs,p,d);call require(d%code==0,'nonadvancing source verified')
 do i=1,p%nc
  if(p%code(i)%op==op_print)wr=i
 end do
 q=p;q%code(wr)%advance_mode=0
 d=diagnostic_t();call verify_frontend(outs,q,d);call require(d%code/=0,'NO cannot be changed to YES')
 q=p;q%code(wr)%advance_mode=2
 d=diagnostic_t();call verify_frontend(outs,q,d);call require(d%code/=0,'invalid ADVANCE metadata adapter')
 d=diagnostic_t();call execute_program(q,d);call require(d%code==2,'invalid ADVANCE metadata runtime')
 q=p;deallocate(q%code(wr)%format)
 d=diagnostic_t();call verify_frontend(outs,q,d);call require(d%code/=0,'nonadvancing list rejected adapter')
 d=diagnostic_t();call execute_program(q,d);call require(d%code==2,'nonadvancing list rejected runtime')
 call parse_subset(prints,p,d);call require(d%code==0,'PRINT source parsed')
 do i=1,p%nc
  if(p%code(i)%op==op_print)wr=i
 end do
 p%code(wr)%advance_mode=1
 d=diagnostic_t();call verify_frontend(prints,p,d);call require(d%code/=0,'source PRINT cannot acquire ADVANCE')
 print *,'PASS: runtime formats native assertions:',checks
contains
 subroutine require(ok,label)
 logical,intent(in)::ok
 character(*),intent(in)::label
 if(.not.ok)then
  print *,label,' mutation:',k
  if(allocated(d%message))print *,d%message
  error stop 'runtime formats assertion failed'
 end if
 checks=checks+1
 end subroutine
end program
