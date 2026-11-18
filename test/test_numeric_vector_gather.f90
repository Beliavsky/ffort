! SPDX-License-Identifier: MIT
! UNVERIFIED source-only native draft; central matching-library execution only.
program test_numeric_vector_gather
 use,intrinsic::iso_fortran_env,only:int64,error_unit
 use fi_ir
 use fi_parser,only:parse_subset
 use fi_frontend,only:verify_frontend
 use fi_runtime,only:execute_program
 use fortfront_compiler
 use ast_nodes_core,only:call_or_subscript_node
 use type_system_unified,only:TINT,TREAL
 implicit none
 character(*),parameter::nl=new_line('a')
 character(:),allocatable::source,decl,kind_text,expression
 type(program_t)::p,q
 type(diagnostic_t)::d
 type(compiler_frontend_options_t)::options
 type(compiler_frontend_result_t)::front
 type(resolved_type_query_t)::typ,selector_type
 integer::checks,t,k,j,g,child,parent,mode,nfound,dummy,proc,expected_kind,expected_type
 checks=0
 do t=1,4
  expected_kind=4
  if(modulo(t,2)==0)expected_kind=8
  if(expected_kind==4)then
   kind_text='4'
  else
   kind_text='8'
  end if
  if(t<=2)then
   decl='integer('//kind_text//')';expected_type=TINT
  else
   decl='real('//kind_text//')';expected_type=TREAL
  end if
  source='program p'//nl//'implicit none'//nl//decl//'::a(-2:1),b(3)'//nl// &
   'integer(8)::idx(3)'//nl//'a=[1,2,3,4]'//nl//'idx=[1_8,-2_8,1_8]'//nl// &
   'b=a(idx)'//nl//'if(any(b/=[4,1,4]))error stop 1'//nl//'end program'
  call baseline('numeric gather')
  d=diagnostic_t();call execute_program(p,d,max_steps=1_int64)
  call require(d%code/=0,'insufficient shared work budget fails')
  d=diagnostic_t();call execute_program(p,d);call require(d%code==0,'later execution is independent')
  g=gather_index(p);child=p%expressions(g)%left
  call require(p%expressions(g)%rank==1.and.child>0,'rank-one selector retained')
  do j=1,37
   q=p
   associate(e=>q%expressions(g))
    select case(j)
    case(1);e%rank=2
    case(2);e%extent=0
    case(3);e%dims=0_int64
    case(4);e%typ=ty_logical
    case(5);e%real_kind=16
    case(6);e%left=0
    case(7);e%right=child
    case(8);e%stride=child
    case(9);e%right2=child
    case(10);e%stride2=child
    case(11);e%right3=child
    case(12);e%stride3=child
    case(13);e%third=child
    case(14);e%triplet(1)=.true.
    case(15);e%triplet(2)=.true.
    case(16);e%triplet(3)=.true.
    case(17);allocate(e%args(0))
    case(18);e%op='forged'
    case(19);e%length_expr=child
    case(20);e%generic_id=1
    case(21);e%bound_type=1
    case(22);e%bound_binding=1
    case(23);e%intrinsic_mask=1
    case(24);e%character_len=1
    case(25);q%symbols(e%symbol)%is_pointer=.true.
    case(26);q%symbols(e%symbol)%rank=2
    case(27);e%symbol=0
    case(28);e%symbol=q%ns+1
    case(29);q%expressions(child)%typ=ty_real
    case(30);q%expressions(child)%rank=0
    case(31);q%expressions(child)%real_kind=16
    case(32);e%left2=child
    case(33);e%left3=child
    case(34);e%left=g
    case(35);e%left=q%ne+1
    case(36);e%real_kind=12-expected_kind
    case(37);q%symbols(e%symbol)%real_kind=12-expected_kind
    end select
   end associate
   d=diagnostic_t();call verify_frontend(source,q,d)
   call require(d%code/=0,'adapter independently rejects forged numeric gather')
   d=diagnostic_t();call execute_program(q,d)
   call require(d%code/=0,'runtime independently rejects forged numeric gather')
  end do
  options%input_mode=INPUT_MODE_STANDARD;options%operating_mode=OPERATING_MODE_STRICT
  options%standardize=.false.;options%run_semantics=.true.
  d=diagnostic_t()
  call compile_frontend_from_string(source,front,options)
  call require(front%success(),'producer accepts numeric rank-one vector section')
  nfound=0
  do k=1,front%arena%entry_count
   if(.not.front%arena%has_node_at(k))cycle
   select type(node=>front%arena%entries(k)%node)
   type is(call_or_subscript_node)
    if(.not.allocated(node%name))cycle
    if(node%name/='a')cycle
    typ=query_resolved_type(front%arena,k)
    call require(node%line==7.and.node%column==8,'producer array access exact source location')
    call require(node%is_array_access.and..not.node%is_intrinsic,'producer identifies array access, not intrinsic')
    call require(allocated(node%arg_indices),'producer retains selector argument')
    call require(size(node%arg_indices)==1,'producer retains exactly one selector argument')
    selector_type=query_resolved_type(front%arena,node%arg_indices(1))
    call require(selector_type%found.and.selector_type%rank==1.and.selector_type%type_kind==TINT.and. &
     selector_type%kind_value==8,'producer preserves INTEGER8 vector selector')
    call require(typ%found.and.typ%rank==1.and.typ%type_kind==expected_type.and. &
     typ%kind_value==expected_kind,'producer preserves numeric rank and kind')
    nfound=nfound+1
   end select
  end do
  call require(nfound==1,'one producer vector section')
 end do
 ! KIND is metadata-only. Empty and cached-empty expressions still validate all
 ! gather fields and the selector expression tree without reading data values.
 do mode=1,4
  if(mode==1)then
   source='program p'//nl//'implicit none'//nl//'real(8),allocatable::a(:)'//nl// &
    'integer::idx(2)'//nl//'if(kind(a(idx))/=8)error stop 1'//nl//'end program'
  else
   expression='a(idx)'
   if(mode==3)expression='-a(idx)'
   if(mode==4)expression='0+a(idx)'
   source='program p'//nl//'implicit none'//nl//'integer::a(3),idx(0),b(0)'//nl// &
    'b='//expression//nl//'if(size(b)/=0)error stop 1'//nl//'end program'
  end if
  call baseline('metadata and empty numeric gather')
  g=gather_index(p);child=p%expressions(g)%left
  if(mode>=3)then
   parent=0
   do k=1,p%ne
    if(mode==3.and.p%expressions(k)%kind/=ex_unary)cycle
    if(mode==4.and.p%expressions(k)%kind/=ex_binary)cycle
    if(p%expressions(k)%left==g.or.p%expressions(k)%right==g)parent=k
   end do
   call require(parent>0,'empty parent exists')
   p%expressions(parent)%extent=0_int64;p%expressions(parent)%dims=[0_int64,1_int64,1_int64]
   d=diagnostic_t();call execute_program(p,d)
   call require(d%code==0,'source-free cached-empty baseline')
  end if
  do j=1,14
   q=p
   associate(e=>q%expressions(g))
    select case(j)
    case(1);e%right3=child
    case(2);e%stride3=child
    case(3);e%left2=child
    case(4);e%left3=child
    case(5);e%third=child
    case(6);e%rank=2
    case(7);e%typ=ty_logical
    case(8);e%extent=0
    case(9);e%dims=0_int64
    case(10);q%expressions(child)%rank=0
    case(11);q%expressions(child)%real_kind=16
    case(12);e%triplet=.true.
    case(13)
     q%expressions(child)%kind=ex_unary;q%expressions(child)%left=child;q%expressions(child)%op='+'
    case(14)
     q%expressions(child)%kind=ex_unary;q%expressions(child)%left=q%ne+1;q%expressions(child)%op='+'
    end select
   end associate
   d=diagnostic_t();call execute_program(q,d)
   call require(d%code/=0,'KIND/empty wrapper rejects malformed gather or selector tree')
  end do
 end do
 ! Public policy predicate: plain assumed-shape input only, exact kind/type.
 source='program p'//nl//'implicit none'//nl//'integer::a(3)'//nl//'a=[1,2,3]'//nl// &
  'call take(a([3,1]))'//nl//'contains'//nl//'subroutine take(x)'//nl// &
  'integer,intent(in)::x(:)'//nl//'if(any(x/=[3,1]))error stop 1'//nl//'end subroutine'//nl//'end program'
 call baseline('bare numeric IN actual')
 g=gather_index(p);proc=0
 do k=1,p%np
  if(p%procedures(k)%name=='take')proc=k
 end do
 call require(proc>0,'callee found');dummy=p%procedures(proc)%args(1)
 call require(bare_numeric_gather_input(p,g,dummy),'numeric eligibility')
 call require(bare_gather_input(p,g,dummy),'combined eligibility')
 call require(.not.bare_character_gather_input(p,g,dummy),'CHARACTER predicate remains separate')
 do j=1,14
  q=p
  select case(j)
  case(1);q%expressions(g)%parenthesized=.true.
  case(2);q%expressions(g)%rank=2
  case(3);q%expressions(g)%typ=ty_logical
  case(4);q%expressions(g)%real_kind=16
  case(5);q%symbols(dummy)%is_dummy=.false.
  case(6);q%symbols(dummy)%dummy_intent=0
  case(7);q%symbols(dummy)%dummy_intent=2
  case(8);q%symbols(dummy)%is_allocatable=.true.
  case(9);q%symbols(dummy)%is_pointer=.true.
  case(10);q%symbols(dummy)%is_target=.true.
  case(11);q%symbols(dummy)%is_class=.true.
  case(12);q%symbols(dummy)%assumed_shape=.false.
  case(13);q%symbols(dummy)%real_kind=8
  case(14);q%symbols(dummy)%rank=2
  end select
  call require(.not.bare_numeric_gather_input(q,g,dummy),'reject ineligible bare numeric policy')
 end do
 call require(.not.bare_gather_input(p,0,dummy),'invalid expression ID')
 call require(.not.bare_gather_input(p,g,0),'invalid dummy ID')
 call require(.not.bare_gather_input(p,p%ne+1,dummy),'out-of-table expression ID')
 call require(.not.bare_gather_input(p,g,p%ns+1),'out-of-table dummy ID')
 ! Retained producer token identity must distinguish a snapshot from a bare
 ! vector section, including keyword/source-order mapping.
 do mode=1,2
  if(mode==1)then
   expression='call copy((a([3,1])),a)'
  else
   expression='call copy(y=a,x=(a([3,1])))'
  end if
  source='program p'//nl//'implicit none'//nl//'integer::a(3)'//nl//'a=[1,2,3]'//nl// &
   expression//nl//'if(any(a/=[3,1,0]))error stop 1'//nl//'contains'//nl// &
   'subroutine copy(x,y)'//nl//'integer,intent(in)::x(:)'//nl//'integer,intent(out)::y(:)'//nl// &
   'y=0'//nl//'y(:size(x))=x'//nl//'end subroutine'//nl//'end program'
  call baseline('parenthesized numeric snapshot and source-marker agreement')
  g=gather_index(p);q=p;q%expressions(g)%parenthesized=.false.
  d=diagnostic_t();call verify_frontend(source,q,d)
  call require(d%code/=0,'adapter rejects stripped source snapshot marker')
  d=diagnostic_t();call execute_program(q,d)
  call require(d%code/=0,'source-free bare overlapping actual rejected')
 end do
 ! The producer anchors function applications at their closing parenthesis.
 ! This exercises both released marker fixes for numeric bare/snapshot actuals.
 do mode=1,2
  if(mode==1)then
   expression='total(a([3,1]))'
  else
   expression='total(v=(a([3,1])))'
  end if
  source='program p'//nl//'implicit none'//nl//'integer::a(3),b'//nl//'a=[1,2,3]'//nl// &
   'b='//expression//nl//'if(b/=4)error stop 1'//nl//'contains'//nl// &
   'function total(v) result(result_value)'//nl//'integer,intent(in)::v(:)'//nl//'integer::result_value'//nl// &
   'result_value=sum(v)'//nl//'end function'//nl//'end program'
  call baseline('numeric gathered function actual and independent marker')
  g=gather_index(p);q=p;q%expressions(g)%parenthesized=.not.p%expressions(g)%parenthesized
  d=diagnostic_t();call verify_frontend(source,q,d)
  call require(d%code/=0,'adapter rejects numeric function source marker mismatch')
 end do
 write(error_unit,'(a,i0)')'numeric vector assertions: ',checks
contains
 subroutine baseline(label)
  character(*),intent(in)::label
  d=diagnostic_t();call parse_subset(source,p,d);call require(d%code==0,'parse '//label)
  d=diagnostic_t();call verify_frontend(source,p,d);call require(d%code==0,'adapter '//label)
  d=diagnostic_t();call execute_program(p,d);call require(d%code==0,'runtime '//label)
 end subroutine
 integer function gather_index(prog) result(index)
  type(program_t),intent(in)::prog
  integer::e
  index=0
  do e=1,prog%ne
   if(prog%expressions(e)%kind==ex_gather_rows)index=e
  end do
  call require(index>0,'gather expression exists')
 end function
 subroutine require(ok,label)
  logical,intent(in)::ok
  character(*),intent(in)::label
  checks=checks+1
  if(.not.ok)then
   write(error_unit,'(a)')label
   if(allocated(d%message))write(error_unit,'(a)')d%message
   error stop 1
  end if
 end subroutine
end program
