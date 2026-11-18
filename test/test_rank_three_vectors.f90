! SPDX-License-Identifier: MIT
! Source-only draft. Compile only in the integrator's approved shared profile.
program test_rank_three_vectors
 use, intrinsic::iso_fortran_env,only:int64,error_unit
 use fi_ir
 use fi_parser,only:parse_subset
 use fi_frontend,only:verify_frontend
 use fi_runtime,only:execute_program
 use fortfront_compiler
 use ast_nodes_bounds,only:array_slice_node
 use ast_nodes_conditional,only:case_block_node,case_default_node
 use fortfront_ast,only:assignment_node
 use type_system_unified,only:TINT
 implicit none
 character(*),parameter::nl=new_line('a')
 character(:),allocatable::source,selector
 type(program_t)::p,q
 type(diagnostic_t)::d
 type(compiler_frontend_options_t)::options
 type(compiler_frontend_result_t)::front
 type(resolved_type_query_t)::typ
 integer::axis,j,k,g,child,checks,nfound,mode,parent,pc,body_index
 integer(int64)::empty_dims(3)
 checks=0
 do axis=1,3
  select case(axis)
  case(1);selector='a(idx,:,:)'
  case(2);selector='a(:,idx,:)'
  case(3);selector='a(:,:,idx)'
  end select
  source='program p'//nl//'implicit none'//nl// &
   'integer::a(3,3,3),idx(2),u,v,w'//nl//'integer,allocatable::b(:,:,:)'//nl// &
   'a=1'//nl//'idx=[3,1]'//nl//'b='//selector//nl// &
   'if(size(b)/=18.or.size(b,'//achar(48+axis)//')/=2)error stop 1'//nl// &
   'do w=1,size(b,3)'//nl//'do v=1,size(b,2)'//nl//'do u=1,size(b,1)'//nl// &
   'if(b(u,v,w)/=1)error stop 2'//nl//'end do'//nl//'end do'//nl//'end do'//nl//'end program'
  d=diagnostic_t();call parse_subset(source,p,d);call require(d%code==0,'parse rank-three gather')
  d=diagnostic_t();call verify_frontend(source,p,d);call require(d%code==0,'independent frontend rank/axis')
  d=diagnostic_t();call execute_program(p,d);call require(d%code==0,'execute baseline gather')
  d=diagnostic_t();call execute_program(p,d,max_steps=1_int64)
  call require(d%code/=0,'bounded execution rejects insufficient work budget')
  d=diagnostic_t();call execute_program(p,d);call require(d%code==0,'budget failure does not poison later execution')
  g=0
  do k=1,p%ne
   if(p%expressions(k)%kind==ex_gather_rows)g=k
  end do
  call require(g>0,'gather expression identified')
  associate(e=>p%expressions(g))
   select case(axis)
   case(1);child=e%left
   case(2);child=e%left2
   case(3);child=e%left3
   end select
   call require(child>0.and.e%rank==3,'axis selector and rank retained')
  end associate
  do j=1,34
   q=p
   associate(e=>q%expressions(g))
    select case(j)
    case(1);e%rank=2
    case(2);e%extent=0
    case(3);e%dims=[2_int64,3_int64,3_int64]
    case(4);e%typ=ty_logical
    case(5);e%real_kind=16
    case(6);e%left=0;e%left2=0;e%left3=0
    case(7);e%right=child
    case(8);e%stride=child
    case(9);e%right2=child
    case(10);e%stride2=child
    case(11);e%right3=child
    case(12);e%stride3=child
    case(13);e%third=child
    case(14);e%triplet=.true.
    case(15);e%triplet=.false.
    case(16);e%triplet(axis)=.true.
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
    case(32);e%left=child;e%left2=child;e%left3=child
    case(33)
     select case(axis)
     case(1);e%left=g
     case(2);e%left2=g
     case(3);e%left3=g
     end select
    case(34)
     select case(axis)
     case(1);e%left=q%ne+1
     case(2);e%left2=q%ne+1
     case(3);e%left3=q%ne+1
     end select
    end select
   end associate
   d=diagnostic_t();call verify_frontend(source,q,d)
   call require(d%code/=0,'adapter rejects forged rank/axis/selector metadata')
   d=diagnostic_t();call execute_program(q,d)
   call require(d%code/=0,'runtime rejects forged rank/axis/selector metadata')
  end do
  ! A syntactically valid alternate axis must not match the original source.
  q=p;q%expressions(g)%triplet=.true.;q%expressions(g)%triplet(modulo(axis,3)+1)=.false.
  q%expressions(g)%left=0;q%expressions(g)%left2=0;q%expressions(g)%left3=0
  select case(modulo(axis,3)+1)
  case(1);q%expressions(g)%left=child
  case(2);q%expressions(g)%left2=child
  case(3);q%expressions(g)%left3=child
  end select
  d=diagnostic_t();call verify_frontend(source,q,d)
  call require(d%code/=0,'adapter binds vector selector to its written axis')
  options%input_mode=INPUT_MODE_STANDARD;options%operating_mode=OPERATING_MODE_STRICT
  options%standardize=.false.;options%run_semantics=.true.
  call compile_frontend_from_string(source,front,options)
  call require(front%success(),'producer accepts tensor vector selector')
  nfound=0
  do k=1,front%arena%entry_count
   if(.not.front%arena%has_node_at(k))cycle
   select type(node=>front%arena%entries(k)%node)
   type is(array_slice_node)
    if(node%num_dimensions/=3)cycle
    typ=query_resolved_type(front%arena,k)
    call require(typ%found.and.typ%rank==3.and.typ%type_kind==TINT,'producer tensor rank/type metadata')
    nfound=nfound+1
   end select
  end do
  call require(nfound==1,'exact producer tensor slice identified')
 end do
 ! Metadata-only KIND and empty values must not bypass descriptor validation.
 do mode=1,2
  do axis=1,3
   select case(axis)
   case(1);selector='a(idx,:,:)'
   case(2);selector='a(:,idx,:)'
   case(3);selector='a(:,:,idx)'
   end select
   if(mode==1) then
    source='program p'//nl//'implicit none'//nl//'real(8),allocatable::a(:,:,:)'//nl// &
     'integer::idx(2)'//nl//'if(kind('//selector//')/=8)error stop 1'//nl//'end program'
   else
    source='program p'//nl//'implicit none'//nl//'integer::a(3,3,3),idx(0)'//nl// &
     'integer,allocatable::b(:,:,:)'//nl//'b='//selector//nl// &
     'if(size(b)/=0)error stop 1'//nl//'end program'
   end if
   d=diagnostic_t();call parse_subset(source,p,d);call require(d%code==0,'parse KIND/empty gather baseline')
   d=diagnostic_t();call verify_frontend(source,p,d);call require(d%code==0,'frontend KIND/empty gather baseline')
   d=diagnostic_t();call execute_program(p,d);call require(d%code==0,'KIND/empty gather reads no base values')
   g=0
   do k=1,p%ne
    if(p%expressions(k)%kind==ex_gather_rows)g=k
   end do
   call require(g>0,'KIND/empty gather expression identified')
   do j=1,8
    q=p
    associate(e=>q%expressions(g))
     select case(j)
     case(1);e%rank=2
     case(2);e%extent=0
     case(3);e%dims=0_int64
     case(4);e%triplet=.true.
     case(5);e%left=0;e%left2=0;e%left3=0
     case(6);e%right3=1
     case(7);e%third=1
     case(8);e%real_kind=16
     end select
    end associate
    d=diagnostic_t();call verify_frontend(source,q,d)
    call require(d%code/=0,'adapter rejects malformed KIND/empty gather')
    d=diagnostic_t();call execute_program(q,d)
    call require(d%code/=0,'KIND/empty runtime independently rejects malformed gather')
   end do
  end do
 end do
 ! Source-free callers may have an already-known empty enclosing shape.
 ! Validate the gather subtree without evaluating skipped data/index values.
 do mode=3,4
  do axis=1,3
   select case(axis)
   case(1);selector='a(idx,:,:)'
   case(2);selector='a(:,idx,:)'
   case(3);selector='a(:,:,idx)'
   end select
   if(mode==3)selector='-'//selector
   if(mode==4)selector='0+'//selector
   source='program p'//nl//'implicit none'//nl//'integer::a(3,3,3),idx(0)'//nl// &
    'integer,allocatable::b(:,:,:)'//nl//'b='//selector//nl// &
    'if(size(b)/=0)error stop 1'//nl//'end program'
   d=diagnostic_t();call parse_subset(source,p,d);call require(d%code==0,'parse empty enclosing gather')
   d=diagnostic_t();call verify_frontend(source,p,d);call require(d%code==0,'frontend empty enclosing gather')
   d=diagnostic_t();call execute_program(p,d);call require(d%code==0,'ordinary empty enclosing gather baseline')
   g=0;parent=0
   do k=1,p%ne
    if(p%expressions(k)%kind==ex_gather_rows)g=k
   end do
   call require(g>0,'empty enclosing gather found')
   do k=1,p%ne
    if(mode==3.and.p%expressions(k)%kind/=ex_unary)cycle
    if(mode==4.and.p%expressions(k)%kind/=ex_binary)cycle
    if(p%expressions(k)%left==g.or.p%expressions(k)%right==g)parent=k
   end do
   call require(parent>0,'empty enclosing unary/binary found')
   select case(axis)
   case(1);child=p%expressions(g)%left
   case(2);child=p%expressions(g)%left2
   case(3);child=p%expressions(g)%left3
   end select
   empty_dims=3_int64;empty_dims(axis)=0_int64
   p%expressions(parent)%extent=0_int64;p%expressions(parent)%dims=empty_dims
   d=diagnostic_t();call execute_program(p,d)
   call require(d%code==0,'source-free cached-empty parent baseline without data reads')
   do j=1,14
    q=p
    associate(e=>q%expressions(g))
     select case(j)
     case(1);e%right3=child
     case(2);e%stride3=child
     case(3);e%right=child
     case(4);e%stride=child
     case(5);e%third=child
     case(6);e%rank=2
     case(7);e%typ=ty_logical
     case(8);e%extent=0
     case(9);e%dims=0_int64
     case(10);q%expressions(child)%rank=0
     case(11);q%expressions(child)%real_kind=16
     case(12);e%triplet=.true.
     case(13)
      q%expressions(child)%kind=ex_unary;q%expressions(child)%left=child
      q%expressions(child)%op='+'
     case(14)
      q%expressions(child)%kind=ex_unary;q%expressions(child)%left=q%ne+1
      q%expressions(child)%op='+'
     end select
    end associate
    d=diagnostic_t();call execute_program(q,d)
    call require(d%code/=0,'cached-empty parent rejects forged gather or selector tree')
   end do
  end do
 end do
 ! The exact utility closure uses semicolon-separated CASE bodies.
 source='program p'//nl//'implicit none'//nl//'integer::n,v'//nl//'v=0'//nl// &
  'do n=1,3'//nl//'select case(n)'//nl//'case(1);v=v+1'//nl// &
  'case(2);v=v+2'//nl//'case default;v=v+3'//nl//'end select'//nl//'end do'//nl// &
  'if(v/=6)error stop 1'//nl//'end program'
 d=diagnostic_t();call parse_subset(source,p,d);call require(d%code==0,'parse inline CASE body')
 d=diagnostic_t();call verify_frontend(source,p,d);call require(d%code==0,'frontend inline CASE body')
 d=diagnostic_t();call execute_program(p,d);call require(d%code==0,'execute every inline CASE body')
 do j=7,9
  pc=0
  do k=1,p%nc
   if(p%code(k)%op==op_assign.and.p%code(k)%line==j)pc=k
  end do
  call require(pc>0,'inline assignment is present at its physical line')
  q=p;q%code(pc)%line=j+1
  d=diagnostic_t();call verify_frontend(source,q,d)
  call require(d%code/=0,'adapter rejects forged inline CASE action location')
 end do
 options%input_mode=INPUT_MODE_STANDARD;options%operating_mode=OPERATING_MODE_STRICT
 options%standardize=.false.;options%run_semantics=.true.
 call compile_frontend_from_string(source,front,options)
 call require(front%success(),'producer accepts inline CASE bodies')
 nfound=0
 do k=1,front%arena%entry_count
  if(.not.front%arena%has_node_at(k))cycle
  body_index=0
  select type(node=>front%arena%entries(k)%node)
  type is(case_block_node)
   call require(allocated(node%body_indices),'CASE has a body list')
   call require(size(node%body_indices)==1,'CASE retains exactly one inline action')
   body_index=node%body_indices(1)
  type is(case_default_node)
   call require(allocated(node%body_indices),'DEFAULT has a body list')
   call require(size(node%body_indices)==1,'DEFAULT retains exactly one inline action')
   body_index=node%body_indices(1)
  end select
  if(body_index==0)cycle
  call require(front%arena%has_node_at(body_index),'inline CASE body node exists')
  select type(action=>front%arena%entries(body_index)%node)
  type is(assignment_node)
   call require(action%line>=7.and.action%line<=9,'inline action keeps physical line')
   call require(action%column==merge(9,14,action%line/=9),'inline action keeps physical column')
  class default
   call require(.false.,'inline CASE body is the original assignment')
  end select
  nfound=nfound+1
 end do
 call require(nfound==3,'all three CASE action bodies retained')
 write(error_unit,'(a,i0)')'rank-three vector assertions: ',checks
contains
 subroutine require(ok,label)
  logical,intent(in)::ok
  character(*),intent(in)::label
  checks=checks+1
  if(ok)return
  write(error_unit,'(a,2i4)')label,axis,j
  if(allocated(d%message))write(error_unit,'(a)')d%message
  error stop 1
 end subroutine
end program
