! SPDX-License-Identifier: MIT
! Source-only independent draft: direct-link only after owner clearance.
program test_fixed_character_derived_scope
 use, intrinsic::iso_fortran_env,only:error_unit
 use fi_ir
 use fi_parser,only:parse_subset
 use fi_runtime,only:execute_program
 implicit none
 character(*),parameter::nl=new_line('a')
 character(*),parameter::source='module m'//nl//'type::box'//nl//'integer::x=3'//nl//'contains'//nl//'procedure::text'//nl// &
 'end type'//nl//'contains'//nl//'character(2) function text(this) result(s)'//nl// &
 'class(box),intent(in)::this'//nl//"write(s,'(i2.2)')this%x"//nl//'end function'//nl// &
 'character(2) function f(b) result(s)'//nl// &
 'type(box),intent(in)::b'//nl//"write(s,'(i2.2)')b%x"//nl//'end function'//nl// &
 'function make() result(b)'//nl//'type(box)::b'//nl//'b=box(6)'//nl//'end function'//nl// &
 'character(2) function g(n) result(s)'//nl//'integer,intent(in)::n'//nl// &
 "write(s,'(i2.2)')n"//nl//'end function'//nl//'end module'//nl// &
 'program p'//nl//'use m'//nl//'type(box)::b'//nl//'character(2)::a(5)'//nl// &
 'b=box(3)'//nl//'a=[f(b),f(box()),f(make()),g(b%x),b%text()]'//nl// &
 "if(any(a/=['03','03','06','03','03']))stop 1"//nl//'end program'
 type(program_t)::p,q
 type(diagnostic_t)::d
 integer::i,var,record,callnode,component,bound,t,s,k,checks,receiver,formal
 checks=0;var=0;record=0;callnode=0;component=0;bound=0
 call parse_subset(source,p,d);call expect(d%code==0,'baseline parses')
 do i=1,p%ne
  if(p%expressions(i)%scope/=0)cycle
  if(p%expressions(i)%kind==ex_user_call.and.p%expressions(i)%bound_type>0)bound=i
  if(is_derived_type(p%expressions(i)%typ))then
   select case(p%expressions(i)%kind)
   case(ex_variable);var=i
   case(ex_record)
    if(allocated(p%expressions(i)%args))then
     if(size(p%expressions(i)%args)==0)record=i
    endif
   case(ex_user_call);callnode=i
   end select
  endif
  if(p%expressions(i)%kind==ex_component)component=i
 enddo
 call expect(min(var,record,callnode,component,bound)>0,'actual identities')
 t=p%expressions(var)%typ-ty_derived_base;s=p%expressions(var)%symbol
 call execute_program(p,d);call expect(d%code==0,'source-free execution')
 receiver=p%expressions(bound)%args(1)
 formal=p%procedures(p%expressions(bound)%symbol)%args(1)
 do k=1,33
  q=p
  select case(k)
  case(1);q%expressions(var)%typ=ty_derived_base+max_types+1
  case(2);q%expressions(var)%symbol=0
  case(3);q%expressions(var)%symbol=p%ns+1
  case(4);q%expressions(var)%rank=1
  case(5);q%expressions(var)%extent=1
  case(6);q%symbols(s)%typ=ty_integer
  case(7);q%expressions(record)%args=[record]
  case(8);q%derived_types(t)%component_initializers(1)=0
  case(9);q%derived_types(t)%component_initializers(1)=p%ne+1
  case(10);q%expressions(callnode)%symbol=0
  case(11);q%expressions(callnode)%symbol=p%np+1
  case(12);q%expressions(callnode)%args=[callnode]
  case(13);q%expressions(component)%symbol=0
  case(14);q%expressions(component)%symbol=17
  case(15);q%expressions(component)%left=component
  case(16);q%expressions(component)%typ=ty_real
  case(17);q%expressions(var)%dims(1)=1
  case(18);q%expressions(var)%real_kind=8
  case(19);q%expressions(var)%character_len=0
  case(20);q%expressions(var)%constructor_owner=record
  case(21);q%derived_types(t)%component_types(1)=ty_derived_base+t
  case(22);q%derived_types(t)%component_kinds(1)=16
  case(23);q%expressions(record)%args=[record,record]
  case(24);q%expressions(bound)%bound_type=max_types+1
  case(25);q%expressions(bound)%bound_binding=17
  case(26);q%expressions(bound)%bound_binding=0
  case(27);q%expressions(bound)%symbol=p%expressions(callnode)%symbol
  case(28);q%expressions(callnode)%typ=ty_integer
  case(29);q%expressions(component)%real_kind=8
  case(30);q%expressions(record)%real_kind=8
  case(31)
   q%nt=p%nt+1;q%derived_types(q%nt)=p%derived_types(t)
   q%derived_types(q%nt)%name='other'
   q%expressions(bound)%bound_type=q%nt
  case(32);q%expressions(bound)%args(1)=record
  case(33);q%symbols(formal)%typ=ty_integer
  end select
  d=diagnostic_t();call execute_program(q,d)
  call expect(d%code/=0,'malformed derived actual rejected')
 enddo
 call dag(.false.,.false.)
 call dag(.true.,.false.)
 call dag(.false.,.true.)
 call dag(.true.,.true.)
 write(error_unit,'(a,i0)')'derived CHARACTER actual scope guards: ',checks
contains
 subroutine dag(arithmetic,eoshift)
  logical,intent(in)::arithmetic,eoshift
  type(program_t)::r
  type(diagnostic_t)::e
  character(:),allocatable::text,replacement
  integer::lo,hi,j,allowed,inquiry
  text=source;lo=index(text,'a=[f(b)');hi=index(text,'if(any(a/')
  if(arithmetic)then
   replacement='a=[g(abs(b%x)),g(kind(1)),g(3),g(3),g(3)]'
  else
   replacement='a=[g(b%x),g(kind(1)),g(3),g(3),g(3)]'
  endif
  if(eoshift)then
   if(arithmetic)then
    replacement='a=[g(abs(b%x)),g(sum(eoshift([1,2],0))),g(3),g(3),g(3)]'
   else
    replacement='a=[g(b%x),g(sum(eoshift([1,2],0))),g(3),g(3),g(3)]'
   endif
  endif
  text=text(:lo-1)//replacement//nl//'end program'
  call parse_subset(text,r,e);call expect(e%code==0,'shared DAG baseline parses')
  allowed=0;inquiry=0
  do j=1,r%ne
   if(r%expressions(j)%scope/=0)cycle
   if(.not.arithmetic.and.r%expressions(j)%kind==ex_component)allowed=j
   if(r%expressions(j)%kind==ex_call)then
    if(arithmetic.and.r%expressions(j)%op=='abs')allowed=j
    if(.not.eoshift.and.r%expressions(j)%op=='kind')inquiry=j
    if(eoshift.and.r%expressions(j)%op=='eoshift')inquiry=j
   endif
  enddo
  call expect(min(allowed,inquiry)>0,'shared DAG identities')
  if(eoshift)then
   r%expressions(inquiry)%args(2)=allowed
  else
   r%expressions(inquiry)%args(1)=allowed
  endif
  call execute_program(r,e)
  call expect(e%code/=0,'strict inquiry rejects memoized scoped component/ancestor')
 end subroutine
 subroutine expect(ok,label)
  logical,intent(in)::ok
  character(*),intent(in)::label
  checks=checks+1
  if(ok)return
  write(error_unit,'(a,i0,2a)')'FAIL ',checks,': ',label
  if(allocated(d%message))write(error_unit,'(a)')d%message
  stop 1
 end subroutine
end program
