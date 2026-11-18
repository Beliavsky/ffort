! Independent direct-IR regression for retained array expressions.
program test_expression_adversarial_review
use, intrinsic::iso_fortran_env,only:int64
use fi_ir
use fi_parser,only:parse_subset
use fi_runtime
implicit none
character(*),parameter::nl=new_line('a')
character(*),parameter::head='program p'//nl//'implicit none'//nl// &
 'integer :: a(3),b(3),x'//nl//'logical :: m(3)'//nl
character(:),allocatable::source
character(7),parameter::reductions(7)=[character(7)::'sum','product','minval','maxval','all','any','count']
type(program_t)::p,q,bad
type(expr_t)::saved
type(expr_t),allocatable::expanded(:)
type(scalar_session_t)::s,clone,t
type(diagnostic_t)::d
type(value_t)::v
type(value_t),allocatable::elements(:)
logical,allocatable::defined(:)
logical::ok
integer(int64)::lo
integer::checks=0,j,k,c,bin,cmp,red,frontier,r
source=head//'a=[1,2,3]'//nl//'b=a+a'//nl//'m=b>3'//nl//'x=sum(b)'//nl
call parse(source,p)
call execute_scalar_session(s,p,d);call check(d%code==0,'fixture execution')
call inspect_scalar_session(s,3,v,ok,d);call check(ok.and.v%i==12,'sum result')
clone=s;frontier=scalar_session_frontier(s)
c=0;bin=0;cmp=0;red=0
 do j=1,p%ne
 select case(p%expressions(j)%kind)
 case(ex_constructor);c=j
 case(ex_binary)
 if(p%expressions(j)%op=='+')bin=j
 if(p%expressions(j)%op=='>')cmp=j
 case(ex_call);red=j
 end select
 end do
call check(min(c,bin,cmp,red)>0,'fixture IR nodes')
do k=1,19
 bad=p
 associate(e=>bad%expressions(c))
 select case(k)
 case(1);e%rank=0
 case(2);e%extent=2
 case(3);e%dims=[3_int64,1_int64,1_int64]
 case(4);e%real_kind=8
 case(5);e%typ=ty_real
 case(6);deallocate(e%args)
 case(7);e%args=[integer::]
 case(8);deallocate(e%args);allocate(e%args(0:2));e%args=p%expressions(c)%args
 case(9);e%args(1)=0
 case(10);e%args(1)=-1
 case(11);e%args(1)=c
 case(12);e%args(1)=p%ne+1
 case(13);e%args(1)=bin
 case(14);e%op='integer'
 case(15);e%symbol=1
 case(16);e%intrinsic_mask=1
 case(17);e%left=1
 case(18);e%value%i=1
 case(19);e%kind=ex_constructor_do
 end select
 end associate
 call reject(bad,'constructor forgery')
end do
do k=1,14
 bad=p
 associate(e=>bad%expressions(bin))
 select case(k)
 case(1);e%rank=0
 case(2);e%extent=2
 case(3);e%dims(1)=3
 case(4);e%real_kind=8
 case(5);e%typ=ty_real
 case(6);e%left=0
 case(7);e%right=bin
 case(8);e%op='**'
 case(9);e%op='//'
 case(10);e%intrinsic_mask=1
 case(11);e%args=[1]
 case(12);e%value%i=1
 case(13);e%right=c
 case(14);e%right=red
 end select
 end associate
 ! Constructor on RHS is genuinely valid same-shape operand, not a forgery.
 if(k==13)then
 d=diagnostic_t();call validate_scalar_session_program(bad,d)
 call check(d%code==0,'valid alternate array child admitted')
 d=diagnostic_t();call execute_scalar_session(s,bad,d)
 call check(d%code/=0.and..not.scalar_session_tainted(s),'changed valid old expression rejected')
 else
 call reject(bad,'binary forgery')
 end if
end do
bad=p;bad%expressions(cmp)%real_kind=8;call reject(bad,'comparison logical kind')
bad=p;bad%expressions(cmp)%typ=ty_integer;call reject(bad,'comparison result type')
bad=p;bad%code(2)%symbol=3;call reject(bad,'array assigned to scalar')
bad=p;bad%code(2)%b=1;call reject(bad,'array assigned to element')
! Every reduction has distinct output/mask invariants.
do r=1,size(reductions)
 call parse(head//'a=1'//nl//'m=.true.'//nl//'print *, '//trim(reductions(r))//'('// &
 merge('a','m',r<=4)//')'//nl,q)
 red=q%ne
 call check(q%expressions(red)%kind==ex_call,'reduction fixture')
 do k=1,12
 bad=q
 associate(e=>bad%expressions(red))
 select case(k)
 case(1);e%rank=1
 case(2);e%extent=1
 case(3);e%dims(1)=1
 case(4);e%intrinsic_mask=merge(1,0,r<=4)
 case(5);e%real_kind=8
 case(6);e%args=[e%args(1),e%args(1)]
 case(7);e%args(1)=0
 case(8);e%args(1)=red
 case(9);e%symbol=1
 case(10);e%left=1
 case(11);e%typ=ty_character
 case(12);e%value%i=1
 end select
 end associate
 call reject(bad,'reduction forgery')
 end do
end do
! Restore fixture prefix, then prove readonly operations and failed runtime do not replay.
call parse(source//'print *, sum(b)'//nl,q)
do k=1,2
 d=diagnostic_t();call execute_scalar_session(s,q,d,commit=.false.)
 call check(d%code==0.and.scalar_session_frontier(s)==frontier,'readonly reduction frontier')
end do
call parse(source//'a=a+1'//nl,q)
d=diagnostic_t();call execute_scalar_session(s,q,d);call check(d%code==0,'alias-safe suffix')
call inspect_session_array(s,1,elements,defined,lo,d)
call check(all(defined).and.all(elements%i==[2,3,4]),'new array values')
call inspect_session_array(clone,1,elements,defined,lo,d)
call check(all(elements%i==[1,2,3]),'deep clone unaffected')
! All actually evaluated elements must be defined, including reductions after decisive logical values.
call parse(head//'a(1)=1'//nl//'x=sum(a)'//nl,q)
call reset_scalar_session(t);call execute_scalar_session(t,q,d)
call check(d%code/=0.and.scalar_session_tainted(t),'partial numeric reduction taints')
call parse(head//'m(1)=.false.'//nl//'print *, all(m)'//nl,q)
call reset_scalar_session(t);call execute_scalar_session(t,q,d)
call check(d%code/=0.and.scalar_session_tainted(t),'logical reduction checks all definedness')
! Canonical retained storage for conversion and empty-reduction identity payloads.
call parse('program p'//nl//'real :: a(2)'//nl//'integer :: b(2),empty(0)'//nl// &
 'a=1'//nl//'b=1.5'//nl//'b=product(empty)'//nl,p)
call reset_scalar_session(t);call execute_scalar_session(t,p,d)
call check(d%code==0,'conversion and empty PRODUCT staging')
call inspect_session_array(t,1,elements,defined,lo,d)
call check(all(elements%r==1.0).and.all(elements%i==0),'real conversion canonical')
call inspect_session_array(t,2,elements,defined,lo,d)
call check(all(elements%i==1).and.all(elements%r==0.0),'identity canonical')
! Shared array expression DAG must obey runtime budget rather than expand exponentially.
call parse('program p'//nl//'integer :: a(1),x'//nl//'a=0'//nl//'x=sum(a+a)'//nl,q)
red=q%ne;saved=q%expressions(red);bin=red-1
call check(q%expressions(bin)%kind==ex_binary,'DAG seed')
allocate(expanded(bin+31));expanded(:bin)=q%expressions(:bin)
do j=bin+1,bin+30
 expanded(j)=expr_t(kind=ex_binary,typ=ty_integer,real_kind=4,rank=1,extent=1_int64, &
  op='+',left=j-1,right=j-1)
end do
expanded(bin+31)=saved;expanded(bin+31)%args=[bin+30]
call move_alloc(expanded,q%expressions);q%ne=bin+31;q%code(q%nc)%a=q%ne
d=diagnostic_t();call validate_scalar_session_program(q,d)
call check(d%code==0,'shared array DAG admitted structurally')
call reset_scalar_session(t);call execute_scalar_session(t,q,d,max_steps=200_int64)
call check(d%code/=0.and.scalar_session_tainted(t),'shared DAG bounded by steps')
! Boundary constructor argument cap, independent of declaration extent.
call parse('program p'//nl//'print *, [1]'//nl,q)
c=q%ne;call check(q%expressions(c)%kind==ex_constructor,'cap seed')
j=q%expressions(c)%args(1)
q%expressions(c)%args=spread(j,1,256);q%expressions(c)%extent=256
q%nc=0
d=diagnostic_t();call validate_scalar_session_program(q,d)
call check(d%code==0,'exact constructor cap')
q%expressions(c)%args=spread(j,1,257);q%expressions(c)%extent=257
d=diagnostic_t();call validate_scalar_session_program(q,d)
call check(d%code/=0,'constructor cap plus one')
print *, 'independent expression checks:',checks
contains
subroutine parse(text,prog)
character(*),intent(in)::text
type(program_t),intent(out)::prog
d=diagnostic_t();call parse_subset(text//'end program'//nl,prog,d)
call check(d%code==0,'fixture parse')
end subroutine
subroutine reject(prog,label)
type(program_t),intent(in)::prog
character(*),intent(in)::label
integer::old
old=scalar_session_frontier(s)
d=diagnostic_t();call validate_scalar_session_program(prog,d)
call check(d%code/=0,label)
d=diagnostic_t();call execute_scalar_session(s,prog,d)
call check(d%code/=0.and..not.scalar_session_tainted(s),'reject without taint')
call check(scalar_session_frontier(s)==old,'reject unchanged frontier')
end subroutine
subroutine check(pass,label)
logical,intent(in)::pass
character(*),intent(in)::label
if(.not.pass)then
 print *, 'FAIL ',label,' case ',k,' reduction ',r
 if(allocated(d%message))print *,d%message
 stop 1
end if
checks=checks+1
end subroutine
end program
