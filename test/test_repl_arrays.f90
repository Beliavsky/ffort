program test_repl_arrays
use, intrinsic::iso_fortran_env,only:int64
use fi_ir
use fi_parser,only:parse_subset
use fi_runtime
implicit none
character(*),parameter::nl=new_line('a'),head='program p'//nl//'implicit none'//nl// &
 'integer :: a(-1:1), empty(2:1)'//nl//'real :: r(2)'//nl//'logical :: b(2)'//nl
character(:),allocatable::src
 type(program_t)::p,q
 type(diagnostic_t)::d
 type(scalar_session_t)::s,t
 type(value_t),allocatable::v(:)
 logical,allocatable::def(:)
 integer(int64)::lo
 integer::checks=0,j
src=head//'a(-1)=4'//nl
call parse(src,p)
call execute_scalar_session(s,p,d);call check(d%code==0,'initial execute')
call inspect_session_array(s,1,v,def,lo,d)
call check(lo==-1.and.size(v)==3,'bounds')
call check(def(1).and..not.any(def(2:)),'partial definedness')
call check(v(1)%i==4,'element value')
t=s
v(1)%i=99
call inspect_session_array(s,1,v,def,lo,d);call check(v(1)%i==4,'copy inspection')
call parse(src//'a(0)=a(-1)+1'//nl,q)
call execute_scalar_session(s,q,d);call check(d%code==0,'element suffix')
call inspect_session_array(s,1,v,def,lo,d);call check(v(2)%i==5.and..not.def(3),'suffix state')
call inspect_session_array(t,1,v,def,lo,d);call check(.not.def(2),'deep owned clone')
src=src//'a(0)=a(-1)+1'//nl//'a=7'//nl//'r=2.5'//nl//'b=.true.'//nl
call parse(src,p);call execute_scalar_session(s,p,d);call check(d%code==0,'broadcast')
call inspect_session_array(s,1,v,def,lo,d);call check(all(def).and.all(v%i==7),'whole retained')
call inspect_session_array(s,2,v,def,lo,d);call check(size(v)==0,'empty retained')
call inspect_session_array(s,3,v,def,lo,d);call check(all(def).and.all(v%r==2.5),'real retained')
call inspect_session_array(s,4,v,def,lo,d);call check(all(def).and.all(v%l),'logical retained')
call parse(src//'print *, a'//nl,q)
call execute_scalar_session(s,q,d,commit=.false.);call check(d%code==0,'whole readonly query')
call execute_scalar_session(s,q,d,commit=.false.);call check(d%code==0,'repeat readonly query')
call parse(src//'a(2)=1'//nl,q)
call execute_scalar_session(s,q,d);call check(d%code/=0.and.scalar_session_tainted(s),'bounds failure taints')
call reset_scalar_session(s)
call parse(head//'print *, a'//nl,p)
call execute_scalar_session(s,p,d);call check(d%code/=0.and.scalar_session_tainted(s),'undefined whole failure')
call reset_scalar_session(s)
call parse('program p'//nl//'integer :: a(100001)'//nl,p)
call execute_scalar_session(s,p,d);call check(d%code/=0.and..not.scalar_session_tainted(s),'aggregate cap')
call parse('program p'//nl//'integer :: a(-2+1:2*2)'//nl//'a=1'//nl,p)
call execute_scalar_session(s,p,d);call check(d%code==0,'constant arithmetic bounds')
call inspect_session_array(s,1,v,def,lo,d);call check(lo==-1.and.size(v)==6,'arithmetic bounds state')
call reset_scalar_session(s)
q=p;q%symbols(1)%upper_bound=7
d=diagnostic_t();call execute_scalar_session(s,q,d)
call check(d%code/=0.and..not.scalar_session_tainted(s),'forged cached bounds')
call parse('program p'//nl//'integer :: a(50001), b(50000)'//nl,p)
call execute_scalar_session(s,p,d);call check(d%code/=0.and..not.scalar_session_tainted(s),'aggregate multi-array cap')
call parse(head//'a=1'//nl//'a=a**2'//nl,p)
call execute_scalar_session(s,p,d);call check(d%code/=0.and..not.scalar_session_tainted(s),'array exponentiation excluded')
call parse(head//'a=1'//nl//'a(0:1)=2'//nl,p)
call execute_scalar_session(s,p,d);call check(d%code/=0.and..not.scalar_session_tainted(s),'sections excluded')
call parse(head//'a=1'//nl//'a=[[1,2,3]]'//nl,p)
call execute_scalar_session(s,p,d);call check(d%code/=0.and..not.scalar_session_tainted(s),'nested constructors excluded')
call parse('program p'//nl//'integer(8) :: a(1)'//nl//'real(8) :: r(1)'//nl// &
 'a=2147483648_8'//nl//'r=1.25_8'//nl,p)
call execute_scalar_session(s,p,d);call check(d%code==0,'kind eight arrays')
call inspect_session_array(s,1,v,def,lo,d)
call check(v(1)%i==2147483648_int64.and.v(1)%real_kind==8,'integer eight retained')
call inspect_session_array(s,2,v,def,lo,d)
call check(v(1)%r==1.25.and.v(1)%real_kind==8,'real eight retained')
call reset_scalar_session(s)
call parse('program p'//nl//'integer :: a(100000)'//nl,p)
call execute_scalar_session(s,p,d);call check(d%code==0,'exact array budget')
call inspect_session_array(s,1,v,def,lo,d)
call check(size(v)==100000.and..not.any(def),'exact budget undefined state')
call reset_scalar_session(s)
call parse('program p'//nl//'integer :: a(0)'//nl,p)
deallocate(p%expressions);allocate(p%expressions(32));p%ne=32
p%expressions(1)=expr_t(kind=ex_literal,typ=ty_integer,real_kind=4)
p%expressions(1)%value=value_t(tag=ty_integer,real_kind=4,i=0_int64)
do j=2,32
    p%expressions(j)=expr_t(kind=ex_binary,typ=ty_integer,real_kind=4,op='+',left=j-1,right=j-1)
end do
p%symbols(1)%upper_expr=32;p%symbols(1)%upper_bound=0
call execute_scalar_session(s,p,d)
call check(d%code/=0.and..not.scalar_session_tainted(s),'shared bound DAG bounded work rejection')
p%ne=10;p%symbols(1)%upper_expr=10
d=diagnostic_t();call execute_scalar_session(s,p,d)
call check(d%code==0,'modest shared bound DAG admitted')
print *, 'array session checks:',checks
contains
subroutine parse(text,p)
character(*),intent(in)::text
type(program_t),intent(out)::p
d=diagnostic_t()
call parse_subset(text//'end program p'//nl,p,d)
call check(d%code==0,'parse')
end subroutine
subroutine check(ok,name)
logical,intent(in)::ok
character(*),intent(in)::name
if(.not.ok)then
print *, 'FAILED ',name
if(allocated(d%message))print *,d%message
stop 1
end if
checks=checks+1
end subroutine
end program
