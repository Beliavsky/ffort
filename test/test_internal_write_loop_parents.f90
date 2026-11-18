program test_internal_write_loop_parents
 use fortfront_compiler
 use fortfront_ast,only:call_or_subscript_node,write_statement_node
 use frontend_compiler_resolution,only:declaration_binding_t,resolve_name_at_node,find_enclosing_scope
 implicit none
 type(compiler_frontend_result_t)::front
 type(compiler_frontend_options_t)::opts
 type(declaration_binding_t)::binding
 character(*),parameter::nl=new_line('a')
 character(:),allocatable::source,loop,err
 integer::mode,i,found,checks
 checks=0
 opts%input_mode=INPUT_MODE_STANDARD;opts%operating_mode=OPERATING_MODE_STRICT
 opts%standardize=.false.;opts%run_semantics=.true.
 do mode=1,3
  select case(mode)
  case(1);loop='do i=1,3'//nl
  case(2);loop='i=1'//nl//'do'//nl//'if(i>3)exit'//nl
  case(3);loop='i=1'//nl//'do while(i<=3)'//nl
  end select
  source='program main'//nl//'implicit none'//nl//'character(2)::a(3)'//nl//'integer::i'//nl// &
    loop//"write(a(i),'(i2.2)')i+4"//nl
  if(mode/=1)source=source//'i=i+1'//nl
  source=source//'end do'//nl//"print '(a)',a"//nl//'end program'//nl
  call compile_frontend_from_string(source,front,opts)
  call expect(front%success(),'producer accepts ordinary loop')
  found=0
  do i=1,front%arena%entry_count
   if(.not.front%arena%has_node_at(i))cycle
   select type(node=>front%arena%entries(i)%node)
   type is(write_statement_node)
    call expect(front%arena%entries(i)%parent_index>0,'WRITE body parent retained')
   type is(call_or_subscript_node)
    if(node%name/='a')cycle
    found=found+1
    call expect(front%arena%entries(i)%parent_index>0,'unit expression parent retained')
    call expect(find_enclosing_scope(front%arena,i)>0,'unit lexical scope exists')
    call resolve_name_at_node(front%arena,i,node%name,binding,err)
    call expect(binding%found.and.binding%declaration_node_index>0,'unit declaration resolves')
    call expect(node%is_array_access.and..not.node%is_intrinsic,'array classification retained')
    call expect(node%resolved_type_found,'unit result metadata resolved')
   end select
  end do
  call expect(found==1,'one original unit expression')
 end do
 print *,'PASS: internal WRITE loop parent assertions:',checks
contains
 subroutine expect(ok,label)
 logical,intent(in)::ok
 character(*),intent(in)::label
 checks=checks+1
 if(ok)return
 print *,label,mode
 if(allocated(front%error_msg))print *,front%error_msg
 error stop 1
 end subroutine
end program
