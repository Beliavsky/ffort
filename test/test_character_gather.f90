program test_character_gather
use fi_ir
use fi_parser,only:parse_subset
use fi_frontend,only:verify_frontend
use fi_runtime,only:execute_program
implicit none
type(program_t)::p
type(diagnostic_t)::d
character(*),parameter::nl=new_line('a')
character(:),allocatable::source
integer::mutation,e,root,s,checks,variant
checks=0
source='implicit none'//nl//'character(3)::x(3)=[character(3)::"one","two","tri"]'//nl// &
 'x=x([3,2,1])'//nl//'if(any(x/=[character(3)::"tri","two","one"]))error stop "gather"'//nl//'end'
do mutation=0,14
 call parse_subset(source,p,d)
 call expect(d%code==0,'parse')
 root=0
 do e=1,p%ne
  if(p%expressions(e)%kind==ex_gather_rows)root=e
 end do
 call expect(root>0,'gather node')
 s=p%expressions(root)%symbol
 select case(mutation)
 case(1);p%expressions(root)%real_kind=8
 case(2);p%expressions(root)%character_len=2
 case(3);p%expressions(root)%rank=2
 case(4);p%expressions(root)%dims(1)=3
 case(5);p%expressions(root)%triplet(1)=.true.
 case(6);p%expressions(root)%triplet(2)=.true.
 case(7);p%expressions(root)%left2=p%expressions(root)%left
 case(8);p%expressions(root)%right=1
 case(9);p%expressions(root)%left=p%ne+1
 case(10);p%expressions(p%expressions(root)%left)%rank=0
 case(11);p%expressions(root)%typ=ty_integer
 case(12);p%symbols(s)%is_pointer=.true.
 case(13);p%expressions(root)%extent=3
 case(14);p%symbols(s)%real_kind=8
 end select
 call verify_frontend(source,p,d)
 call expect((d%code==0).eqv.(mutation==0),'independent adapter')
 d=diagnostic_t()
 call execute_program(p,d)
 call expect((d%code==0).eqv.(mutation==0),'runtime')
end do
! Inquiry and zero-trip paths must reject malformed lengths without data reads.
do variant=1,2
 source='implicit none'//nl//'character(3)::x(1),y(0)'//nl//'integer::i'//nl
 if(variant==1)then
  source=source//'if(kind(x([integer::]))/=1)error stop "kind"'//nl//'end'
 else
  source=source//'y=[(x([1]),i=1,0)]'//nl//'end'
 end if
 do mutation=0,2
  call parse_subset(source,p,d)
  call expect(d%code==0,'metadata-only parse')
  root=0
  do e=1,p%ne
   if(p%expressions(e)%kind==ex_gather_rows)root=e
  end do
  call expect(root>0,'metadata-only gather')
  if(mutation/=0)then
   s=p%expressions(root)%symbol
   p%expressions(root)%character_len=merge(-2,65537,mutation==1)
   p%symbols(s)%character_len=p%expressions(root)%character_len
  end if
  call verify_frontend(source,p,d)
  call expect((d%code==0).eqv.(mutation==0),'metadata-only adapter')
  d=diagnostic_t()
  call execute_program(p,d)
  call expect((d%code==0).eqv.(mutation==0),'metadata-only runtime')
 end do
end do
! Only run against guarded candidate: reject before gathered string allocation.
source='implicit none'//nl//'character(65536)::x(1)'//nl//'integer::idx(257)'//nl// &
 'x="a"'//nl//'idx=1'//nl//'if(size(x(idx))/=257)error stop "extent"'//nl//'end'
call parse_subset(source,p,d)
call expect(d%code==0,'budget parse')
call verify_frontend(source,p,d)
call expect(d%code==0,'budget adapter')
call execute_program(p,d)
call expect(d%code/=0,'budget rejects')
call expect(d%message=='CHARACTER gather temporary byte limit exceeded (16777216)','budget exact diagnostic')
! Small malformed selected PARAMETER payloads: no large unsafe allocation.
source='implicit none'//nl//'character(3),parameter::x(1)=["abc"]'//nl// &
 'if(any(x([1])/=["abc"]))error stop "payload"'//nl//'end'
do mutation=0,6
 call parse_subset(source,p,d)
 call expect(d%code==0,'selected payload parse')
 s=0
 do e=1,p%ns
  if(p%symbols(e)%name=='x')s=e
 end do
 call expect(s>0,'selected payload symbol')
 select case(mutation)
 case(1);deallocate(p%symbols(s)%constant_values(1)%s)
 case(2);p%symbols(s)%constant_values(1)%tag=ty_integer
 case(3);p%symbols(s)%constant_values(1)%real_kind=8
 case(4);p%symbols(s)%constant_values(1)%s='ab'
 case(5);allocate(p%symbols(s)%constant_values(1)%record)
 case(6);p%symbols(s)%constant_values(1)%s='abcd'
 end select
 call execute_program(p,d)
 call expect((d%code==0).eqv.(mutation==0),'selected payload rejected')
end do
! Each gather individually fits; two live caches together exceed the byte cap.
source='implicit none'//nl//'character(65536)::x(1)'//nl//'integer::idx(129)'//nl// &
 'x="a"'//nl//'idx=1'//nl// &
 'if(sum(index(x(idx),"a")+index(x(idx),"a"))/=258)error stop "sum"'//nl//'end'
call parse_subset(source,p,d)
call expect(d%code==0,'aggregate budget parse')
call verify_frontend(source,p,d)
call expect(d%code==0,'aggregate budget adapter')
call execute_program(p,d)
call expect(d%code/=0,'aggregate budget rejects')
call expect(d%message=='CHARACTER gather temporary byte limit exceeded (16777216)','aggregate exact diagnostic')
print*,'PASS CHARACTER gather checks:',checks
contains
subroutine expect(ok,label)
logical,intent(in)::ok
character(*),intent(in)::label
checks=checks+1
if(ok)return
print*,mutation,label
if(allocated(d%message))print*,d%message
error stop 'CHARACTER gather assertion'
end subroutine
end program
