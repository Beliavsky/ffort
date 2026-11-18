program test_array_intrinsics_independent
use, intrinsic::iso_fortran_env,only:int64
use fi_ir
use fi_parser,only:parse_subset
use fi_runtime
implicit none
character(*),parameter::nl=new_line('a')
character(5)::ops(7)=[character(5)::'abs','sqrt','sin','cos','exp','log','log10']
character(6)::inq(3)=[character(6)::'size','lbound','ubound']
character(:),allocatable::src
 type(program_t)::p,bad,q
 type(scalar_session_t)::s
 type(diagnostic_t)::d
 type(value_t)::v
 logical::defined
 integer::checks=0,i,j,k,callidx,n,fr
! Elemental arrays: every additional metadata field remains canonical.
do i=1,size(ops)
 src='program p'//nl//'real :: a(3),b(3)'//nl//'a=2.0'//nl//'b='//trim(ops(i))//'(a)'//nl//'end program'
 call parse(src,p);call validate_scalar_session_program(p,d);call check(d%code==0,'elemental admitted')
 callidx=0
 do j=1,p%ne
  if(p%expressions(j)%kind==ex_call.and.p%expressions(j)%op==ops(i))callidx=j
 end do
 call check(callidx>0,'elemental root')
 bad=p;bad%expressions(callidx)%rank=0;call reject(bad,'elemental forged scalar result')
 bad=p;bad%expressions(callidx)%extent=2;call reject(bad,'elemental extent mismatch')
 bad=p;bad%expressions(callidx)%typ=ty_integer;call reject(bad,'elemental type mismatch')
 bad=p;bad%expressions(callidx)%real_kind=8;call reject(bad,'elemental kind mismatch')
 bad=p;bad%expressions(callidx)%intrinsic_mask=1;call reject(bad,'elemental hidden mask')
 bad=p;bad%expressions(callidx)%symbol=1;call reject(bad,'elemental hidden symbol')
 bad=p;bad%expressions(callidx)%left=1;call reject(bad,'elemental hidden left')
 bad=p;bad%expressions(callidx)%args=[integer::];call reject(bad,'elemental zero arguments')
 bad=p;bad%expressions(callidx)%args=[1,1];call reject(bad,'elemental two arguments')
 bad=p;deallocate(bad%expressions(callidx)%args);call reject(bad,'elemental absent arguments')
 do k=-1,p%ne+1
  if(k>=1.and.k<callidx)cycle
  bad=p;bad%expressions(callidx)%args=[k];call reject(bad,'elemental bad argument index')
 end do
 call reset_scalar_session(s);call execute_scalar_session(s,p,d);call check(d%code==0,'elemental executes')
end do
! Inquiry shape metadata must not read uninitialized elements.
do i=1,3
 src='program p'//nl//'integer :: a(-2:2),n'//nl//'n='//trim(inq(i))//'(a,1)'//nl//'end program'
 call parse(src,p);call validate_scalar_session_program(p,d);call check(d%code==0,'inquiry admitted')
 callidx=0
 do j=1,p%ne
  if(p%expressions(j)%kind==ex_call.and.p%expressions(j)%op==inq(i))callidx=j
 end do
 call check(callidx>0,'inquiry root')
 call reset_scalar_session(s);call execute_scalar_session(s,p,d);call check(d%code==0,'undefined array inquiry allowed')
 call inspect_scalar_session(s,2,v,defined,d)
 n=5;if(i==2)n=-2
 if(i==3)n=2
 call check(defined.and.v%i==n,'correct inquiry result')
 fr=scalar_session_frontier(s)
 bad=p;bad%expressions(callidx)%rank=1;bad%expressions(callidx)%extent=1;call reject(bad,'inquiry forged array result')
 bad=p;bad%expressions(callidx)%typ=ty_real;call reject(bad,'inquiry forged result type')
 bad=p;bad%expressions(callidx)%real_kind=8;call reject(bad,'inquiry forged result kind')
 bad=p;bad%expressions(callidx)%args=[integer::];call reject(bad,'inquiry zero args')
 bad=p;bad%expressions(callidx)%args=[1,1,1];call reject(bad,'inquiry excess args')
 bad=p;bad%expressions(callidx)%args(2)=callidx;call reject(bad,'DIM cycle')
 bad=p;bad%expressions(callidx)%args(1)=p%ne+1;call reject(bad,'inquiry array out of bounds')
 bad=p;bad%expressions(callidx)%intrinsic_mask=7;call reject(bad,'inquiry forged mask')
 bad=p;bad%expressions(callidx)%extent=10;call reject(bad,'inquiry hidden extent')
 call execute_scalar_session(s,bad,d);call check(d%code/=0,'invalid query rejected before effects')
 call check(.not.scalar_session_tainted(s).and.scalar_session_frontier(s)==fr,'invalid query preserves healthy state')
 d=diagnostic_t();call inspect_scalar_session(s,2,v,defined,d);call check(defined.and.v%i==n,'invalid query preserves value')
end do
! No-DIM bounds are rank-one length-one INTEGER arrays with a distinct mask.
do i=2,3
 call parse('program p'//nl//'integer :: a(-2:2),n(1)'//nl// &
 'n='//trim(inq(i))//'(a)'//nl//'end program',p)
 call validate_scalar_session_program(p,d);call check(d%code==0,'no-DIM bound admitted')
 do j=1,p%ne
  if(p%expressions(j)%kind==ex_call.and.p%expressions(j)%op==inq(i))callidx=j
 end do
 bad=p;bad%expressions(callidx)%rank=0;call reject(bad,'no-DIM scalar forgery')
 bad=p;bad%expressions(callidx)%extent=2;call reject(bad,'no-DIM extent forgery')
 bad=p;bad%expressions(callidx)%intrinsic_mask=3;call reject(bad,'no-DIM mask forgery')
 bad=p;bad%expressions(callidx)%intrinsic_mask=5;call reject(bad,'no-DIM KIND mask')
 call reset_scalar_session(s);call execute_scalar_session(s,p,d);call check(d%code==0,'no-DIM undefined array executes')
end do
call parse('program p'//nl//'integer :: a(2),n'//nl//'n=size(a)'//nl//'end program',p)
call reset_scalar_session(s);call execute_scalar_session(s,p,d);call check(d%code==0,'SIZE no-DIM undefined array executes')
call inspect_scalar_session(s,2,v,defined,d);call check(defined.and.v%i==2,'SIZE no-DIM value')
call parse('program p'//nl//'integer :: a(2),n'//nl//'n=size(a,2)'//nl//'end program',p)
call validate_scalar_session_program(p,d);call check(d%code==0,'DIM value validation belongs to runtime')
call reset_scalar_session(s);call execute_scalar_session(s,p,d);call check(d%code/=0.and.scalar_session_tainted(s),'invalid DIM fails and taints')
call parse('program p'//nl//'real :: a(2),b(2)'//nl//'b=sin(a)'//nl//'end program',p)
call reset_scalar_session(s);call execute_scalar_session(s,p,d)
call check(d%code/=0.and.scalar_session_tainted(s),'elemental undefined values fail and taint')
print *, 'independent array intrinsic checks:',checks
contains
subroutine parse(src,out)
character(*),intent(in)::src
type(program_t),intent(out)::out
d=diagnostic_t();call parse_subset(src//nl,out,d);call check(d%code==0,'parse')
end subroutine
subroutine check(ok,label)
logical,intent(in)::ok
character(*),intent(in)::label
if(.not.ok)then
print *,'FAILED ',label
if(allocated(d%message))print *,d%message
stop 1
end if
checks=checks+1
end subroutine
subroutine reject(candidate,label)
type(program_t),intent(in)::candidate
character(*),intent(in)::label
d=diagnostic_t();call validate_scalar_session_program(candidate,d);call check(d%code/=0,label)
d=diagnostic_t()
end subroutine
end program
