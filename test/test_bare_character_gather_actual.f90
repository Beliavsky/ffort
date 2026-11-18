program test_bare_character_gather_actual
use fi_ir
use fi_parser,only:parse_subset
use fi_frontend,only:verify_frontend
use fi_runtime,only:execute_program
implicit none
type(program_t)::p
type(diagnostic_t)::d
character(*),parameter::nl=new_line('a')
character(:),allocatable::source
integer::mutation,e,f,root,dummy,checks,variant
checks=0
source='module m'//nl//'contains'//nl//'subroutine consume(v)'//nl// &
 'character(*),intent(in)::v(:)'//nl// &
 'if(any(v/=["ef","ab","ef"]))error stop "gather"'//nl// &
 'end subroutine'//nl//'end module'//nl//'program main'//nl//'use m'//nl// &
 'implicit none'//nl//'character(2)::x(3)=["ab","cd","ef"]'//nl// &
 'call consume(x([3,1,3]))'//nl//'end program'
do mutation=0,10
 call parse_subset(source,p,d)
 call expect(d%code==0,'bare input parse')
 root=0;dummy=0
 do e=1,p%ne
  if(p%expressions(e)%kind==ex_gather_rows)root=e
 end do
 do f=1,p%np
  if(p%procedures(f)%name=='consume')dummy=p%procedures(f)%args(1)
 end do
 call expect(root>0.and.dummy>0,'gather and input dummy')
 select case(mutation)
 case(1);p%symbols(dummy)%dummy_intent=2
 case(2);p%symbols(dummy)%is_allocatable=.true.
 case(3);p%symbols(dummy)%is_pointer=.true.
 case(4);p%symbols(dummy)%is_target=.true.
 case(5);p%symbols(dummy)%assumed_shape=.false.
 case(6);p%expressions(root)%rank=2
 case(7);p%expressions(root)%real_kind=8
 case(8);p%expressions(root)%typ=ty_real
 case(9);p%symbols(dummy)%rank=0
 case(10);p%symbols(dummy)%typ=ty_real
 end select
 call verify_frontend(source,p,d)
 call expect((d%code==0).eqv.(mutation==0),'independent source adapter')
 d=diagnostic_t()
 call execute_program(p,d)
 call expect((d%code==0).eqv.(mutation==0),'independent runtime')
end do
! A valid parenthesized snapshot is independent of the output descriptor.
! Removing only that marker changes the alias contract, not the value shape.
source='module m'//nl//'contains'//nl//'subroutine copy(v,y)'//nl// &
 'character(*),intent(in)::v(:)'//nl// &
 'character(*),allocatable,intent(out)::y(:)'//nl// &
 'allocate(y(size(v)))'//nl//'y=v'//nl//'end subroutine'//nl// &
 'end module'//nl//'program main'//nl//'use m'//nl//'implicit none'//nl// &
 'character(2),allocatable::x(:)'//nl//'allocate(x(3))'//nl// &
 'x=["ab","cd","ef"]'//nl//'call copy((x([3,1])),x)'//nl// &
 'if(any(x/=["ef","ab"]))error stop "copy"'//nl//'end program'
do variant=0,1
 call parse_subset(source,p,d)
 call expect(d%code==0,'same-base snapshot parse')
 root=0
 do e=1,p%ne
  if(p%expressions(e)%kind==ex_gather_rows)root=e
 end do
 call expect(root>0,'same-base gather')
 if(variant==1)p%expressions(root)%parenthesized=.false.
 call verify_frontend(source,p,d)
 call expect((d%code==0).eqv.(variant==0),'snapshot adapter marker')
 d=diagnostic_t();call execute_program(p,d)
 call expect((d%code==0).eqv.(variant==0),'snapshot runtime alias contract')
 if(variant==1)call expect(index(d%message,'bare CHARACTER gather base overlaps')>0,'named alias diagnostic')
end do
! An empty bare section still reserves its base against a writable descriptor.
source='module m'//nl//'contains'//nl//'subroutine copy(v,y)'//nl// &
 'character(*),intent(in)::v(:)'//nl// &
 'character(*),allocatable,intent(out)::y(:)'//nl// &
 'allocate(y(size(v)))'//nl//'y=v'//nl//'end subroutine'//nl// &
 'end module'//nl//'program main'//nl//'use m'//nl//'implicit none'//nl// &
 'character(2),allocatable::x(:)'//nl//'allocate(x(3))'//nl// &
 'x=["ab","cd","ef"]'//nl//'call copy((x([integer::])),x)'//nl// &
 'if(size(x)/=0)error stop "empty"'//nl//'end program'
do variant=0,1
 call parse_subset(source,p,d)
 call expect(d%code==0,'empty snapshot parse')
 root=0
 do e=1,p%ne
  if(p%expressions(e)%kind==ex_gather_rows)root=e
 end do
 call expect(root>0,'empty gather')
 if(variant==1)p%expressions(root)%parenthesized=.false.
 call verify_frontend(source,p,d)
 call expect((d%code==0).eqv.(variant==0),'empty adapter marker')
 d=diagnostic_t();call execute_program(p,d)
 call expect((d%code==0).eqv.(variant==0),'empty runtime alias contract')
 if(variant==1)call expect(index(d%message,'bare CHARACTER gather base overlaps')>0,'empty alias diagnostic')
end do
! Module/host associations remain distinct from a computed expression.
source='module m'//nl//'implicit none'//nl// &
 'character(2)::x(2)=["ab","cd"]'//nl//'contains'//nl// &
 'subroutine consume(v)'//nl//'character(*),intent(in)::v(:)'//nl// &
 'x="zz"'//nl//'if(any(v/=["cd","ab"]))error stop "snapshot"'//nl// &
 'end subroutine'//nl//'end module'//nl//'program main'//nl//'use m'//nl// &
 'implicit none'//nl//'call consume((x([2,1])))'//nl//'end program'
do variant=0,1
 call parse_subset(source,p,d)
 call expect(d%code==0,'module snapshot parse')
 root=0
 do e=1,p%ne
  if(p%expressions(e)%kind==ex_gather_rows)root=e
 end do
 call expect(root>0,'module gather')
 if(variant==1)p%expressions(root)%parenthesized=.false.
 call verify_frontend(source,p,d)
 call expect((d%code==0).eqv.(variant==0),'module marker adapter')
 d=diagnostic_t();call execute_program(p,d)
 call expect((d%code==0).eqv.(variant==0),'module bare association runtime')
 if(variant==1)call expect(index(d%message,'module actual conflicts')>0,'named host diagnostic')
end do
print *,'PASS: bare CHARACTER gather argument assertions:',checks
contains
subroutine expect(ok,label)
logical,intent(in)::ok
character(*),intent(in)::label
if(.not.ok)then
 print *,'FAIL: ',label
 error stop 1
end if
checks=checks+1
end subroutine
end program
