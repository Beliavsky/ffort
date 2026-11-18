! SPDX-License-Identifier: MIT
program test_inquire_name_producer
use fortfront_compiler
use ast_nodes_io,only:inquire_statement_node
implicit none
type(compiler_frontend_options_t)::opts
type(compiler_frontend_result_t)::front
type(resolved_type_query_t)::typ
character(*),parameter::nl=new_line('a')
character(:),allocatable::source,body,stmt,unit_decl
integer::form,kind_case,i,j,n,checks
opts%input_mode=INPUT_MODE_STANDARD;opts%operating_mode=OPERATING_MODE_STRICT
opts%standardize=.false.;opts%run_semantics=.true.;checks=0
do kind_case=1,2
 unit_decl='integer::iu'
 if(kind_case==2)unit_decl='integer(8)::iu'
 do form=1,5
  stmt='inquire(unit=iu,name=nm)'
  if(form==2)stmt='inquire(name=nm,unit=iu)'
  if(form==3)stmt='inquire(unit=iu, &'//nl//' & name=nm)'
  body=stmt//nl
  if(form==4)body='do j=1,2'//nl//body//'end do'//nl
  if(form==5)body='if(iu>0)then'//nl//body//'end if'//nl
  source='program p'//nl//'implicit none'//nl//unit_decl//nl//'integer::j'//nl// &
   'character(24)::nm'//nl//body//'end program'
  call compile_frontend_from_string(source,front,opts)
  call expect(front%success(),'frontend success');n=0
  do i=1,front%arena%entry_count
   if(.not.front%arena%has_node_at(i))cycle
   select type(node=>front%arena%entries(i)%node)
   type is(inquire_statement_node)
    n=n+1
    call expect(allocated(node%specifiers),'specifier allocation')
    call expect(size(node%specifiers)==2,'two controls')
    call expect(node%iostat_var_index==0.and.node%err_label_index==0,'no hidden options')
    do j=1,2
     call expect(allocated(node%specifiers(j)%name).and.allocated(node%specifiers(j)%value),'control text')
     call expect(front%arena%has_node_at(node%specifiers(j)%value_node_index),'source value node')
     typ=query_resolved_type(front%arena,node%specifiers(j)%value_node_index)
     call expect(typ%found.and.typ%rank==0,'scalar source type')
     select case(node%specifiers(j)%name)
     case('unit')
      call expect(node%specifiers(j)%value=='iu'.and.typ%type_kind==TINT,'UNIT source binding')
      call expect(typ%kind_value==4*kind_case,'UNIT source kind')
     case('name')
      call expect(node%specifiers(j)%value=='nm'.and.typ%type_kind==TCHAR,'NAME source binding')
     case default
      error stop 'unexpected INQUIRE control'
     end select
    end do
   end select
  end do
  call expect(n==1,'exact inquiry count')
 end do
end do
print '(a,i0,a)','PASS: ',checks,' INQUIRE producer assertions'
contains
subroutine expect(ok,label)
logical,intent(in)::ok
character(*),intent(in)::label
checks=checks+1
if(ok)return
print *,kind_case,form,label
if(allocated(front%error_msg))print *,front%error_msg
error stop 'INQUIRE producer assertion failed'
end subroutine
end program
