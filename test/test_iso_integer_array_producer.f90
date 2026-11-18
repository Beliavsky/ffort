! SPDX-License-Identifier: MIT
program test_iso_integer_array_producer
use fortfront_compiler
use fortfront_ast,only:call_or_subscript_node,identifier_node
use ast_nodes_bounds,only:array_slice_node
use frontend_compiler_resolution,only:declaration_binding_t,resolve_name_at_node, &
 BINDING_INTRINSIC_ARRAY,BINDING_DECLARATION
implicit none
character(*),parameter::nl=new_line('a')
type(compiler_frontend_options_t)::opts
type(compiler_frontend_result_t)::front
type(resolved_type_query_t)::typ
type(declaration_binding_t)::binding
character(:),allocatable::source,message
integer::checks
opts%input_mode=INPUT_MODE_STANDARD;opts%operating_mode=OPERATING_MODE_STRICT
opts%standardize=.false.;opts%run_semantics=.true.;checks=0
call query('use,intrinsic::iso_fortran_env,only:integer_kinds', &
 'integer_kinds(1)','integer_kinds',4,0,.true.)
call query('use,intrinsic::iso_fortran_env,only:integer_kinds', &
 'integer_kinds(2:1:-1)','integer_kinds',4,1,.true.)
call query('use::iso_fortran_env,only:integer_kinds', &
 'integer_kinds(1)','integer_kinds',4,0,.true.)
call query('use,intrinsic::iso_fortran_env,only:k=>integer_kinds', &
 'k(2)','k',4,0,.true.)
call query('use,intrinsic::iso_fortran_env,only:k=>integer_kinds', &
 'k([2,1])','k',4,1,.true.)
call query('use,intrinsic::iso_fortran_env,k=>integer_kinds', &
 'k(2:1:-1)','k',4,1,.true.)
call query('use,intrinsic::iso_fortran_env,only:integer_kinds', &
 'integer_kinds','integer_kinds',4,1,.false.)
source='module m'//nl//'use,intrinsic::iso_fortran_env,only:k=>integer_kinds'//nl// &
 'contains'//nl//'subroutine s()'//nl//'print *,k(1)'//nl//'end subroutine'//nl// &
 'end module'//nl//'program p'//nl//'end program'
call inspect(source,'k',4,0,.true.,BINDING_INTRINSIC_ARRAY)
! Explicit local data and a local dummy shadow the intrinsic spelling/host name.
call query('integer(8)::integer_kinds(2)','integer_kinds(1)', &
 'integer_kinds',8,0,.true.,BINDING_DECLARATION)
source='module m'//nl//'use,intrinsic::iso_fortran_env,only:integer_kinds'//nl// &
 'contains'//nl//'subroutine s(integer_kinds)'//nl// &
 'integer(8)::integer_kinds(2)'//nl//'print *,integer_kinds(1)'//nl// &
 'end subroutine'//nl//'end module'//nl//'program p'//nl//'end program'
! Declaration-backed dummy lookup is expected to return its typed declaration.
call inspect(source,'integer_kinds',8,0,.true.,BINDING_DECLARATION)
source='module iso_fortran_env'//nl//'integer(8)::integer_kinds(2)'//nl// &
 'end module'//nl//'program p'//nl// &
 'use,non_intrinsic::iso_fortran_env,only:integer_kinds'//nl// &
 'print *,integer_kinds(1)'//nl//'end program'
call inspect(source,'integer_kinds',8,0,.true.,BINDING_DECLARATION)
source='module iso_fortran_env'//nl//'integer(8)::integer_kinds(2)'//nl// &
 'end module'//nl//'program p'//nl// &
 'use::iso_fortran_env,only:integer_kinds'//nl// &
 'print *,integer_kinds(1)'//nl//'end program'
call inspect(source,'integer_kinds',8,0,.true.,BINDING_DECLARATION)
source='module iso_fortran_env'//nl//'integer(8)::integer_kinds(2)'//nl// &
 'end module'//nl//'program p'//nl// &
 'use,intrinsic::iso_fortran_env,only:integer_kinds'//nl// &
 'print *,integer_kinds(1)'//nl//'end program'
call inspect(source,'integer_kinds',4,0,.true.,BINDING_INTRINSIC_ARRAY)
! A later source module must not retroactively capture an earlier USE.
source='program p'//nl//'use::iso_fortran_env,only:integer_kinds'//nl// &
 'print *,integer_kinds(1)'//nl//'end program'//nl// &
 'module iso_fortran_env'//nl//'integer::other=77'//nl//'end module'
call inspect(source,'integer_kinds',4,0,.true.,BINDING_INTRINSIC_ARRAY)
print *,'PASS: ISO integer array producer assertions:',checks
contains
subroutine query(declaration,expression,name,k,r,array,bindkind)
character(*),intent(in)::declaration,expression,name
integer,intent(in)::k,r
logical,intent(in)::array
integer,optional,intent(in)::bindkind
integer::b
b=BINDING_INTRINSIC_ARRAY;if(present(bindkind))b=bindkind
call inspect('program p'//nl//declaration//nl//'print *,'//expression//nl// &
 'end program',name,k,r,array,b)
end subroutine
subroutine inspect(text,name,k,r,array,bindkind)
character(*),intent(in)::text,name
integer,intent(in)::k,r,bindkind
logical,intent(in)::array
integer::i,found
call compile_frontend_from_string(text,front,opts)
if(.not.front%success())then
 if(allocated(front%error_msg))print *,front%error_msg
 error stop 'ISO array producer compile'
endif
checks=checks+1;found=0
 do i=1,front%arena%entry_count
  if(.not.front%arena%has_node_at(i))cycle
  select type(node=>front%arena%entries(i)%node)
  type is(call_or_subscript_node)
   if(.not.array)cycle
   if(.not.allocated(node%name))cycle
   if(node%name/=name)cycle
   call verify(i,name,k,r,bindkind,found)
   if(node%is_intrinsic.or..not.node%is_array_access)error stop 'ISO array identity flags'
   checks=checks+1
  type is(array_slice_node)
   if(.not.array)cycle
   if(.not.front%arena%has_node_at(node%array_index))cycle
   select type(base=>front%arena%entries(node%array_index)%node)
   type is(identifier_node)
    if(.not.allocated(base%name))cycle
    if(base%name/=name)cycle
   class default
    cycle
   end select
   call verify(i,name,k,r,bindkind,found)
   if(node%num_dimensions/=1.or.node%is_character_substring)error stop 'ISO slice identity flags'
   checks=checks+1
  type is(identifier_node)
   if(array)cycle
   if(.not.allocated(node%name))cycle
   if(node%name/=name)cycle
   call verify(i,name,k,r,bindkind,found)
  end select
 enddo
 if(found/=1)error stop 'ISO array occurrence count'
 checks=checks+1
end subroutine
subroutine verify(index,name,k,r,bindkind,found)
integer,intent(in)::index,k,r,bindkind
character(*),intent(in)::name
integer,intent(inout)::found
typ=query_resolved_type(front%arena,index)
if(.not.typ%found.or.typ%type_kind/=TINT.or.typ%kind_value/=k.or.typ%rank/=r) &
 error stop 'ISO array independent metadata'
checks=checks+1;found=found+1
call resolve_name_at_node(front%arena,index,name,binding,message)
if(.not.binding%found.or.binding%binding_kind/=bindkind)error stop 'ISO array scoped binding'
checks=checks+1
if(bindkind==BINDING_INTRINSIC_ARRAY)then
 if(.not.allocated(binding%module_name).or..not.allocated(binding%remote_name)) &
  error stop 'ISO array remote allocation'
 if(binding%module_name/='iso_fortran_env'.or.binding%remote_name/='integer_kinds') &
  error stop 'ISO array remote identity'
 if(binding%declaration_node_index/=0.or.binding%scope_node_index<=0.or.binding%node_index<=0) &
  error stop 'ISO array source USE ownership'
 checks=checks+1
endif
end subroutine
end program
