program test_character_components
use, intrinsic::iso_fortran_env,only:int64
use fi_ir
use fi_parser,only:parse_subset
use fi_frontend,only:verify_frontend
use fi_runtime,only:execute_program
implicit none
type(program_t)::p
type(diagnostic_t)::d
type(value_t)::arguments(1),returned
character(*),parameter::nl=new_line('a')
character(:),allocatable::source
integer::mutation,root,checks,e,variant,boundary,j
checks=0
source='module m'//nl//'implicit none'//nl//'type::dt'//nl//'character(len=3)::s="cat"'//nl// &
 'end type'//nl//'end module'//nl//'program main'//nl//'use m'//nl//'implicit none'//nl// &
 'type(dt)::x,z'//nl//'x%s="abcdef"'//nl//'z=x'//nl//'x%s="q"'//nl// &
 'if(z%s/="abc".or.x%s/="q  ".or.len(x%s)/=3) error stop "values"'//nl//'end program'
do mutation=0,19
 call parse_subset(source,p,d)
 call expect(d%code==0,'parse baseline')
 root=p%derived_types(1)%component_length_exprs(1)
 call expect(root>0,'length expression retained')
 select case(mutation)
 case(1);p%derived_types(1)%component_lengths(1)=-1
 case(2);p%derived_types(1)%component_lengths(1)=65537
 case(3);p%derived_types(1)%component_lengths(1)=2
 case(4);p%derived_types(1)%component_kinds(1)=8
 case(5);p%derived_types(1)%component_length_exprs(1)=-1
 case(6);p%derived_types(1)%component_length_exprs(1)=p%ne+1
 case(7);p%derived_types(1)%component_length_exprs(1)=0
 case(8);p%derived_types(1)%component_lengths(2)=3
 case(9);p%derived_types(1)%component_length_exprs(2)=root
 case(10);p%expressions(root)%typ=ty_real
 case(11);p%expressions(root)%rank=1
 case(12);p%expressions(root)%scope=0
 case(13);p%derived_types(1)%component_types(1)=ty_integer
 case(16,17,18,19)
  do e=1,p%ne
   if(p%expressions(e)%kind==ex_component) then
    if(mutation==16)p%expressions(e)%dims(1)=1
    if(mutation==17)p%expressions(p%expressions(e)%left)%real_kind=8
    if(mutation==18)p%expressions(p%expressions(e)%left)%dims(1)=1
    if(mutation==19)p%expressions(p%expressions(e)%left)%character_len=1
    exit
   end if
  end do
 case(15)
  do e=1,p%ne
   if(p%expressions(e)%kind==ex_component) then
    p%expressions(e)%real_kind=8
    exit
   end if
  end do
 case(14)
  do e=1,p%ne
   if(p%expressions(e)%kind==ex_component) then
    p%expressions(e)%character_len=2
    exit
   end if
  end do
 end select
 call verify_frontend(source,p,d)
 call expect((d%code==0).eqv.(mutation==0),'adapter mutation')
 d=diagnostic_t()
 call execute_program(p,d)
 call expect((d%code==0).eqv.(mutation==0),'runtime mutation')
end do
do variant=1,2
 source='module m'//nl//'implicit none'//nl//'type::dt'//nl//'character(len=3)::s'
 if(variant==1)source=source//'="cat"'
 source=source//nl//'end type'//nl//'end module'//nl//'program main'//nl//'use m'//nl// &
  'implicit none'//nl//'type(dt)::x'//nl
 if(variant==2)source=source//'x%s="cat"'//nl
 source=source//'end program'
 do mutation=0,1
  call parse_subset(source,p,d)
  call expect(d%code==0,'no-read parser')
  root=p%derived_types(1)%component_initializers(1)
  if(variant==2)then
   do e=1,p%ne
    if(p%expressions(e)%kind==ex_literal.and.p%expressions(e)%typ==ty_character)root=e
   end do
  end if
  call expect(root>0,'no-read literal root')
  if(mutation==1)p%expressions(root)%value%real_kind=8
  call verify_frontend(source,p,d)
  call expect((d%code==0).eqv.(mutation==0),'no-read adapter kind guard')
  d=diagnostic_t()
  call execute_program(p,d)
  call expect((d%code==0).eqv.(mutation==0),'no-read runtime kind guard')
 end do
end do
source='module m'//nl//'implicit none'//nl//'type::dt'//nl//'character(len=65536)::s="cat"'//nl// &
 'end type'//nl//'end module'//nl//'program main'//nl//'use m'//nl//'implicit none'//nl// &
 'type(dt)::x'//nl//'end program'
boundary=int((max_derived_character_bytes/2_int64-2_int64*65536_int64)/(8_int64*65536_int64))
do variant=0,1
 call parse_subset(source,p,d)
 call expect(d%code==0,'budget parser')
 call expect(boundary>=1.and.boundary+1<=size(p%symbols),'budget native bounds')
 do j=2,boundary+variant
  p%symbols(j)=p%symbols(1)
 end do
 p%ns=boundary+variant
 d=diagnostic_t()
 call execute_program(p,d)
 call expect((d%code==0).eqv.(variant==0),'safe budget boundary')
 if(variant==1)call expect(d%message== &
  'derived CHARACTER storage reservation limit exceeded; adjust max_derived_character_bytes','budget diagnostic')
end do
source='module m'//nl//'implicit none'//nl//'type::dt'//nl//'character(3)::s="cat"'//nl// &
 'end type'//nl//'end module'//nl//'program main'//nl//'use m'//nl//'implicit none'//nl// &
 'type(dt)::x'//nl//'x=dt("abc")'//nl//'end program'
call parse_subset(source,p,d)
call expect(d%code==0,'cycle parser')
root=0
do e=1,p%ne
 if(p%expressions(e)%kind==ex_record)root=e
end do
call expect(root>0,'cycle record')
p%expressions(root)%args(1)=root
call execute_program(p,d)
call expect(d%code/=0,'cycle rejected before allocation')
call expect(d%message=='cyclic or excessive derived CHARACTER expression structure','cycle diagnostic')
source='module m'//nl//'implicit none'//nl//'type::dt'//nl//'character(65536)::s="cat"'//nl// &
 'end type'//nl//'contains'//nl//'function echo(v) result(answer)'//nl//'type(dt),intent(in)::v'//nl// &
 'type(dt)::answer'//nl//'answer=v'//nl//'end function'//nl//'end module'//nl//'program main'//nl// &
 'use m'//nl//'implicit none'//nl//'type(dt)::x,z'//nl//'z=echo(x)'//nl//'end program'
call parse_subset(source,p,d)
call expect(d%code==0,'DAG parser')
root=0
do e=1,p%ne
 if(p%expressions(e)%kind==ex_user_call)root=e
end do
call expect(root>0,'DAG record call')
e=p%expressions(root)%args(1)
deallocate(p%expressions(root)%args)
allocate(p%expressions(root)%args(15),source=e)
call execute_program(p,d)
call expect(d%code/=0,'repeated derived edges reserve each payload')
call expect(d%message== &
 'derived CHARACTER storage reservation limit exceeded; adjust max_derived_character_bytes','DAG diagnostic')
source='module m'//nl//'implicit none'//nl//'type::dt'//nl//'character(3)::s'//nl// &
 'end type'//nl//'contains'//nl//'function width(v) result(n)'//nl//'type(dt),intent(in)::v'//nl// &
 'integer::n'//nl//'n=len(v%s)'//nl//'end function'//nl//'end module'//nl// &
 'program main'//nl//'use m'//nl//'implicit none'//nl//'end program'
do mutation=0,9
 call parse_subset(source,p,d)
 call expect(d%code==0,'record argument parser')
 arguments(1)=value_t(tag=ty_derived_base+1)
 allocate(arguments(1)%record)
 allocate(arguments(1)%record%components(1),arguments(1)%record%component_defined(1))
 arguments(1)%record%component_defined=.true.
 arguments(1)%record%components(1)=component_value_t(tag=ty_character)
 arguments(1)%record%components(1)%s='cat'
 select case(mutation)
 case(1);arguments(1)%record%components(1)%s='cats'
 case(2);arguments(1)%record%components(1)%tag=ty_integer
 case(3);arguments(1)%record%components(1)%real_kind=8
 case(4);deallocate(arguments(1)%record%components(1)%s)
 case(5);deallocate(arguments(1)%record%components)
 case(6);deallocate(arguments(1)%record)
 case(7);arguments(1)%s='hidden'
 case(8)
  deallocate(arguments(1)%record%component_defined)
  allocate(arguments(1)%record%component_defined(0))
 case(9)
  arguments(1)%record%component_defined=.false.
  deallocate(arguments(1)%record%components(1)%s)
 end select
 call execute_program(p,d,procedure_index=1,argument_values=arguments,procedure_value=returned)
 call expect((d%code==0).eqv.(mutation==0.or.mutation==9),'record argument schema')
 if(d%code==0)call expect(returned%tag==ty_integer.and.returned%i==3_int64,'metadata-only argument LEN')
end do
! Zero-length fields still require schema-valid incoming payloads.
source='module m'//nl//'implicit none'//nl//'type::dt'//nl//'character(0)::s'//nl// &
 'end type'//nl//'contains'//nl//'function width(v) result(n)'//nl//'type(dt),intent(in)::v'//nl// &
 'integer::n'//nl//'n=len(v%s)'//nl//'end function'//nl//'end module'//nl// &
 'program main'//nl//'use m'//nl//'implicit none'//nl//'end program'
do mutation=0,1
 call parse_subset(source,p,d)
 call expect(d%code==0,'zero field parser')
 arguments(1)=value_t(tag=ty_derived_base+1)
 allocate(arguments(1)%record)
 allocate(arguments(1)%record%components(1),arguments(1)%record%component_defined(1))
 arguments(1)%record%component_defined=.true.
 arguments(1)%record%components(1)=component_value_t(tag=ty_character)
 arguments(1)%record%components(1)%s=''
 if(mutation==1)arguments(1)%record%components(1)%s='x'
 call execute_program(p,d,procedure_index=1,argument_values=arguments,procedure_value=returned)
 call expect((d%code==0).eqv.(mutation==0),'zero field schema validation')
 if(mutation==0)call expect(returned%i==0_int64,'zero field LEN')
end do
! Tiny malformed caches must be rejected before value_t deep copies.
source='module m'//nl//'implicit none'//nl//'type::dt'//nl//'character(3)::s'//nl// &
 'end type'//nl//'end module'//nl//'program main'//nl//'use m'//nl//'implicit none'//nl// &
 'type(dt)::x'//nl//'integer::i=1'//nl//'end program'
do mutation=1,6
 call parse_subset(source,p,d)
 call expect(d%code==0,'cache parser')
 arguments(1)=value_t(tag=ty_derived_base+1)
 allocate(arguments(1)%record)
 allocate(arguments(1)%record%components(1),arguments(1)%record%component_defined(1))
 arguments(1)%record%component_defined=.true.
 arguments(1)%record%components(1)=component_value_t(tag=ty_character)
 arguments(1)%record%components(1)%s='x'
 if(mod(mutation,2)==0)arguments(1)%tag=ty_integer
 select case(mutation)
 case(1,2)
  p%expressions(1)%value=arguments(1)
 case(3,4)
  p%symbols(1)%constant_value=arguments(1)
 case(5,6)
  if(allocated(p%symbols(1)%constant_values))deallocate(p%symbols(1)%constant_values)
  allocate(p%symbols(1)%constant_values(1))
  p%symbols(1)%constant_values(1)=arguments(1)
 end select
 call execute_program(p,d)
 call expect(d%code/=0,'record-bearing cache rejected')
end do
source='module m' //nl// &
 'implicit none' //nl// &
 'type::dt' //nl// &
 'character(65536)::s=''cat''' //nl// &
 'contains' //nl// &
 'procedure::output' //nl// &
 'generic::write(formatted)=>output' //nl// &
 'end type' //nl// &
 'contains' //nl// &
 'subroutine output(dtv,unit,iotype,v_list,iostat,iomsg)' //nl// &
 'class(dt),intent(in)::dtv' //nl// &
 'integer,intent(in)::unit' //nl// &
 'character(len=*),intent(in)::iotype' //nl// &
 'integer,intent(in)::v_list(:)' //nl// &
 'integer,intent(out)::iostat' //nl// &
 'character(len=*),intent(inout)::iomsg' //nl// &
 'write(unit,''(a)'',iostat=iostat,iomsg=iomsg) trim(dtv%s)' //nl// &
 'end subroutine' //nl// &
 'end module' //nl// &
 'use m' //nl// &
 'implicit none' //nl// &
 'type(dt)::x' //nl// &
 'print ''(dt)'',x' //nl// &
 'end'
call parse_subset(source,p,d)
call expect(d%code==0,'derived output parser')
root=0
do e=1,p%nc
 if(p%code(e)%op==op_print)root=e
end do
call expect(root>0,'derived output instruction')
e=p%code(root)%items(1)
deallocate(p%code(root)%items)
allocate(p%code(root)%items(257),source=e)
call execute_program(p,d)
call expect(d%code/=0,'derived staged output bytes bounded')
call expect(d%message=='output CHARACTER temporary limit exceeded (16777216)','staged output diagnostic')
print*,'PASS CHARACTER component checks:',checks
contains
subroutine expect(ok,label)
logical,intent(in)::ok
character(*),intent(in)::label
checks=checks+1
if(ok)return
print*,mutation,label
if(allocated(d%message))print*,d%message
error stop 'CHARACTER component invariant'
end subroutine
end program
