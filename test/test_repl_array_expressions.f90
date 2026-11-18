program test_repl_array_expressions
use, intrinsic::iso_fortran_env,only:int64,real64
use fi_ir
use fi_parser,only:parse_subset
use fi_runtime
implicit none
character(*),parameter::nl=new_line('a')
character(*),parameter::head='program p'//nl//'integer :: a(-1:1),b(3),e(2:1),i,n,prod,mn,mx,cnt'//nl// &
 'real :: r(3)'//nl//'real(8) :: r8(3)'//nl//'integer(8) :: i8(3)'//nl//'logical :: mask(3),yes,no'//nl
character(:),allocatable::body,text
 type(program_t)::p,q,bad
 type(diagnostic_t)::d
 type(scalar_session_t)::s,t
 type(value_t)::v
 type(value_t),allocatable::av(:)
 logical,allocatable::flags(:)
 logical::defined
 integer(int64)::lbound_value
 integer::checks=0,j,k,node,ctor,red,bin,oldfrontier
body='a=[1,2,3]'//nl//'b=a'//nl//'a=a+2*b'//nl//'a=-a'//nl// &
 'mask=(a < -4).and..true.'//nl//'n=sum(a)'//nl//'prod=product(a)'//nl// &
 'mn=minval(a)'//nl//'mx=maxval(a)'//nl//'cnt=count(mask)'//nl//'yes=any(mask)'//nl//'no=all(mask)'//nl
call parse(body,p);call execute_scalar_session(s,p,d);call check(d%code==0,'array expression execution')
call array_i(1,[-3_int64,-6_int64,-9_int64],'self reference arithmetic')
call scalar_i(5,-18_int64,'sum');call scalar_i(6,-162_int64,'product')
call scalar_i(7,-9_int64,'minval');call scalar_i(8,-3_int64,'maxval');call scalar_i(9,2_int64,'count')
call inspect_scalar_session(s,14,v,defined,d);call check(defined.and.v%l,'any')
call inspect_scalar_session(s,15,v,defined,d);call check(defined.and..not.v%l,'all')
t=s;oldfrontier=scalar_session_frontier(s)
call parse(body//'print *,sum(a),a'//nl,q)
! Ordinary appended PRINT can have several items; ephemeral query is exactly one.
call validate_scalar_session_query(q,p%nc,d);call check(d%code/=0,'multi item query rejected')
call parse(body//'print *,sum(a)'//nl,q)
call execute_scalar_session(s,q,d,commit=.false.);call check(d%code==0,'sum readonly query')
call execute_scalar_session(s,q,d,commit=.false.);call check(d%code==0,'repeated sum readonly query')
call check(scalar_session_frontier(s)==oldfrontier,'readonly frontier')
body=body//'a=a+1'//nl//'do i=-1,1'//nl//'if (a(i)<0) a(i)=a(i)-1'//nl//'end do'//nl
call parse(body,q);call execute_scalar_session(s,q,d);call check(d%code==0,'expressions with counted loop IF')
call array_i(1,[-3_int64,-6_int64,-9_int64],'suffix not replayed')
call inspect_session_array(t,1,av,flags,lbound_value,d);call check(all(av%i==[-3,-6,-9]),'deep clone array')
! Trusted conversion outputs and empty reduction identities must become canonical.
body=body//'r=1'//nl//'a=1.5'//nl//'b=product(e)'//nl//'e=e+1'//nl// &
 'r8=[1.0_8,2.0_8,3.0_8]'//nl//'i8=[1_8,2_8,3_8]'//nl//'r8=r8/2.0_8'//nl// &
 'mask=.not.mask.or..false.'//nl
call parse(body,p);call execute_scalar_session(s,p,d);call check(d%code==0,'conversion and empty identities')
call array_i(1,[1_int64,1_int64,1_int64],'real to integer broadcast')
call array_i(2,[1_int64,1_int64,1_int64],'empty product broadcast')
call inspect_session_array(s,10,av,flags,lbound_value,d)
call check(all(flags).and.all(av%r==1.0_real64).and.all(av%i==0),'integer real broadcast canonical')
call inspect_session_array(s,11,av,flags,lbound_value,d)
call check(all(flags).and.all(av%r==[0.5_real64,1.0_real64,1.5_real64]),'real8 arithmetic')
call inspect_session_array(s,12,av,flags,lbound_value,d)
call check(all(flags).and.all(av%i==[1,2,3]).and.all(av%real_kind==8),'integer8 constructor')
call execute_scalar_session(s,p,d);call check(d%code==0,'canonical restore after conversions')
body=body//'a=minval(e)'//nl//'b=maxval(e)'//nl
call parse(body,p);call execute_scalar_session(s,p,d);call check(d%code==0,'empty extrema broadcast')
call array_i(1,[2147483647_int64,2147483647_int64,2147483647_int64],'empty minval')
call array_i(2,[-2147483648_int64,-2147483648_int64,-2147483648_int64],'empty maxval')
! Constructor scalar expressions/reductions and both scalar operand positions.
call reset_scalar_session(s)
body='a=[1,2,3]'//nl//'b=[a(-1),sum(a),abs(-2)]'//nl//'a=2+a'//nl//'a=10-a'//nl// &
 'a=2*a'//nl//'a=100/a'//nl//'mask=(a>=1).eqv..true.'//nl
call parse(body,p);call execute_scalar_session(s,p,d);call check(d%code==0,'scalar items and operand positions')
call array_i(2,[1_int64,6_int64,2_int64],'scalar constructor items')
! Exact metadata rejection, before effects, on actual array-node shapes.
ctor=0;red=0;bin=0
do j=1,p%ne
 if(p%expressions(j)%kind==ex_constructor.and.ctor==0)ctor=j
 if(p%expressions(j)%kind==ex_call.and.p%expressions(j)%op=='sum')red=j
 if(p%expressions(j)%kind==ex_binary.and.p%expressions(j)%rank==1)bin=j
end do
call check(ctor>0.and.red>0.and.bin>0,'mutation nodes found')
bad=p;bad%expressions(ctor)%extent=2;call reject(bad,'constructor extent')
bad=p;bad%expressions(ctor)%args(1)=ctor;call reject(bad,'constructor cycle')
bad=p;bad%expressions(ctor)%op='integer';call reject(bad,'typed constructor')
bad=p;bad%expressions(ctor)%constructor_owner=1;call reject(bad,'constructor hidden owner')
bad=p;bad%expressions(ctor)%dims=[3_int64,1_int64,1_int64];call reject(bad,'rank1 dims default exact')
bad=p;deallocate(bad%expressions(ctor)%args);allocate(bad%expressions(ctor)%args(0:2)); &
 bad%expressions(ctor)%args=p%expressions(ctor)%args;call reject(bad,'shifted args')
bad=p;bad%expressions(red)%intrinsic_mask=1;call reject(bad,'numeric reduction mask')
bad=p;bad%expressions(red)%real_kind=8;call reject(bad,'reduction kind')
bad=p;bad%expressions(red)%rank=1;call reject(bad,'reduction result rank')
bad=p;bad%expressions(red)%args=[p%expressions(red)%args(1),1];call reject(bad,'optional reduction argument')
bad=p;bad%expressions(bin)%extent=2;call reject(bad,'binary extent')
bad=p;bad%expressions(bin)%real_kind=8;call reject(bad,'logical result kind')
bad=p;bad%expressions(bin)%left=bin;call reject(bad,'binary cyclic child')
call check(.not.scalar_session_tainted(s),'rejections preserve taint flag')
! Unsupported source forms still reject at admission.
call unsupported('r=1.0'//nl//'r=r+1'//nl,'mixed type array op')
call unsupported('i8=1_8'//nl//'i8=i8+1'//nl,'mixed kind array op')
call unsupported('a=1'//nl//'a=a**2'//nl,'array power')
call unsupported('a=[[1,2,3]]'//nl,'nested constructor')
call unsupported('a=[b]'//nl,'array constructor item')
call unsupported('a=1'//nl//'n=sum(a,dim=1)'//nl,'reduction DIM')
call unsupported('a=1'//nl//'r=a'//nl,'mixed whole copy')
call unsupported('a=1'//nl//'a(0:1)=2'//nl,'sections')
! Errors taint and never silently replay; low budgets bound DAG execution.
call reset_scalar_session(s);call parse('a=1'//nl//'a=[1,2,3]'//nl,p)
call execute_scalar_session(s,p,d,max_steps=5_int64)
call check(d%code/=0.and.scalar_session_tainted(s),'constructor low budget taints')
call reset_scalar_session(s);call parse('a(-1)=1'//nl//'n=sum(a)'//nl,p)
call execute_scalar_session(s,p,d);call check(d%code/=0.and.scalar_session_tainted(s),'undefined reduction taints')
call reset_scalar_session(s);call parse('a=2147483647'//nl//'a=a+1'//nl,p)
call execute_scalar_session(s,p,d);call check(d%code/=0.and.scalar_session_tainted(s),'array overflow taints')
! Exact constructor cap and aggregate argument edge budget (ascending admission).
call reset_scalar_session(s)
text='program p'//nl//'integer :: a(256)'//nl//'a=['
do j=1,256
 if(j>1)text=text//','
 if(mod(j,32)==0)text=text//'&'//nl//'&'
 text=text//'1'
end do
text=text//']'//nl//'end program p'
d=diagnostic_t();call parse_subset(text,p,d);call check(d%code==0,'parse cap256')
call execute_scalar_session(s,p,d);call check(d%code==0,'constructor cap256 admitted')
node=0
do j=1,p%ne
 if(p%expressions(j)%kind==ex_constructor)node=j
end do
bad=p;bad%expressions(node)%args=[p%expressions(node)%args,1];bad%expressions(node)%extent=257
call reject(bad,'constructor cap257')
! Legal shared scalar DAG with exponential evaluation is structurally linear to
! admit and then promptly stopped by normal runtime steps.
call reset_scalar_session(s)
p=program_t();p%name='dag';p%ns=1;p%ne=34;p%nc=1
allocate(p%symbols(1),p%expressions(34),p%code(1))
p%symbols(1)=symbol_t(name='a',typ=ty_integer,rank=1,upper_expr=1,upper_bound=3_int64)
p%expressions(1)=expr_t(kind=ex_literal,typ=ty_integer);p%expressions(1)%value=value_t(tag=ty_integer,i=3_int64)
p%expressions(2)=expr_t(kind=ex_literal,typ=ty_integer);p%expressions(2)%value=value_t(tag=ty_integer,i=0_int64)
do j=3,33
 p%expressions(j)=expr_t(kind=ex_binary,typ=ty_integer,op='+',left=j-1,right=j-1)
end do
p%expressions(34)=expr_t(kind=ex_constructor,typ=ty_integer,rank=1,extent=3_int64)
p%expressions(34)%args=[33,33,33]
p%code(1)=instruction_t(op=op_assign,symbol=1,a=34)
d=diagnostic_t();call validate_scalar_session_program(p,d);call check(d%code==0,'shared DAG admission')
call execute_scalar_session(s,p,d,max_steps=100_int64)
call check(d%code/=0.and.scalar_session_tainted(s),'shared DAG budget taints promptly')
! Aggregate edge cap is independent of per-constructor and retained storage caps.
p=program_t();p%name='edges';p%ns=0;p%nc=0;p%ne=392
allocate(p%symbols(0),p%code(0),p%expressions(393))
p%expressions(1)=expr_t(kind=ex_literal,typ=ty_integer)
p%expressions(1)%value=value_t(tag=ty_integer,i=1_int64)
do j=2,391
 p%expressions(j)=expr_t(kind=ex_constructor,typ=ty_integer,rank=1,extent=256_int64)
 allocate(p%expressions(j)%args(256));p%expressions(j)%args=1
end do
p%expressions(392)=expr_t(kind=ex_constructor,typ=ty_integer,rank=1,extent=160_int64)
allocate(p%expressions(392)%args(160));p%expressions(392)%args=1
d=diagnostic_t();call validate_scalar_session_program(p,d);call check(d%code==0,'exact aggregate edge cap')
p%ne=393;p%expressions(393)=expr_t(kind=ex_constructor,typ=ty_integer,rank=1,extent=1_int64)
p%expressions(393)%args=[1]
call reject(p,'aggregate edge cap plus one')
! Aggregate rank-one expression extent counts variable nodes too, with no DAG recursion.
p=program_t();p%name='extent';p%ns=1;p%nc=0;p%ne=11
allocate(p%symbols(1),p%code(0),p%expressions(12))
p%symbols(1)=symbol_t(name='a',typ=ty_integer,rank=1,upper_expr=1,upper_bound=100000_int64)
p%expressions(1)=expr_t(kind=ex_literal,typ=ty_integer)
p%expressions(1)%value=value_t(tag=ty_integer,i=100000_int64)
do j=2,12
 p%expressions(j)=expr_t(kind=ex_variable,typ=ty_integer,rank=1,extent=100000_int64,symbol=1)
end do
d=diagnostic_t();call validate_scalar_session_program(p,d);call check(d%code==0,'exact aggregate extent cap')
p%ne=12;call reject(p,'aggregate extent cap exceeded')
print *, 'retained array expression checks:',checks
contains
subroutine parse(src,p)
character(*),intent(in)::src
type(program_t),intent(out)::p
d=diagnostic_t();call parse_subset(head//src//'end program p'//nl,p,d);call check(d%code==0,'parse')
end subroutine
subroutine check(ok,name)
logical,intent(in)::ok
character(*),intent(in)::name
if(.not.ok)then
 print *,'FAILED ',name
 if(allocated(d%message))print *,d%message
 stop 1
end if
checks=checks+1
end subroutine
subroutine scalar_i(idx,want,name)
integer,intent(in)::idx
integer(int64),intent(in)::want
character(*),intent(in)::name
call inspect_scalar_session(s,idx,v,defined,d);call check(d%code==0.and.defined.and.v%i==want,name)
end subroutine
subroutine array_i(idx,want,name)
integer,intent(in)::idx
integer(int64),intent(in)::want(:)
character(*),intent(in)::name
call inspect_session_array(s,idx,av,flags,lbound_value,d)
call check(d%code==0.and.size(av)==size(want),name//' size')
call check(all(flags).and.all(av%i==want),name)
end subroutine
subroutine reject(bad,name)
type(program_t),intent(in)::bad
character(*),intent(in)::name
d=diagnostic_t();call validate_scalar_session_program(bad,d);call check(d%code/=0,name)
end subroutine
subroutine unsupported(src,name)
character(*),intent(in)::src,name
call parse(src,bad);call reject(bad,name)
end subroutine
end program
