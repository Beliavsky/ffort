program test_repl_select_independent
use, intrinsic :: iso_fortran_env, only:int64
use fi_ir
use fi_parser, only:parse_subset
use fi_runtime
implicit none
character(*),parameter::nl=new_line('a')
type(program_t)::p,bad,q
type(scalar_session_t)::s
type(diagnostic_t)::d
type(value_t)::v
integer::checks=0,j,k,a,c1,c2,c3,inner,br,loop,fr,idx,depth
logical::defined
call parse('program p'//nl//'integer :: i,n'//nl//'i=2'//nl//'n=0'//nl// &
 'select case(i)'//nl//'case(1)'//nl//'n=10'//nl//'case(2:3)'//nl//'n=20'//nl// &
 'case default'//nl//'n=30'//nl//'end select'//nl//'end program',p)
call validate_scalar_session_program(p,d);call check(d%code==0,'integer select admitted')
a=0;c1=0;c2=0;c3=0
do j=1,p%nc
 if(p%code(j)%op==op_select)a=j
 if(p%code(j)%op/=op_case)cycle
 if(c1==0)then
 c1=j
 else if(c2==0)then
 c2=j
 else
 c3=j
 end if
end do
call check(a>0.and.c3>0,'find select and cases')
call execute_scalar_session(s,p,d);call check(d%code==0,'execute baseline')
call inspect_scalar_session(s,2,v,defined,d);call check(defined.and.v%i==20,'range matching')
fr=scalar_session_frontier(s)
call execute_scalar_session(s,p,d);call check(d%code==0.and.scalar_session_frontier(s)==fr,'identical no replay frontier')
! Each chain target and owner is uniquely prescribed by structure.
do j=1,p%nc
 if(p%code(j)%op/=op_select.and.p%code(j)%op/=op_case)cycle
 do k=0,p%nc+2
  bad=p;bad%code(j)%target=k
  call validate_scalar_session_program(bad,d)
  call check((d%code==0).eqv.(k==p%code(j)%target),'exhaustive chain destination')
  d=diagnostic_t()
 end do
 if(p%code(j)%op==op_case)then
  do k=0,p%nc+1
   if(k==a)cycle
   bad=p;bad%code(j)%a=k;call reject(bad,'forged case owner')
  end do
 end if
 bad=p;bad%code(j)%symbol=1;call reject(bad,'hidden symbol')
 bad=p;bad%code(j)%b=1;call reject(bad,'hidden b')
 bad=p;bad%code(j)%c=1;call reject(bad,'hidden c')
 bad=p;bad%code(j)%d=1;call reject(bad,'hidden d')
 bad=p;bad%code(j)%scope=1;call reject(bad,'hidden scope')
 bad=p;bad%code(j)%format='(I0)';call reject(bad,'hidden format')
 bad=p;bad%code(j)%format_expr=1;call reject(bad,'hidden runtime format')
 bad=p;bad%code(j)%advance_mode=1;call reject(bad,'hidden advance')
end do
bad=p;deallocate(bad%code(c1)%items);call reject(bad,'missing case items')
bad=p;bad%code(c1)%items=[1];call reject(bad,'odd case items')
bad=p;bad%code(c1)%items=[0,0];call reject(bad,'empty range')
bad=p;bad%code(c1)%items=[-1,-1];call reject(bad,'negative range expressions')
bad=p;bad%code(c1)%items=[p%ne+1,p%ne+1];call reject(bad,'range expression overflow')
bad=p;bad%code(c1)%items=[integer::];call reject(bad,'duplicate default')
bad=p;bad%code(c1)%items=p%code(c2)%items;call reject(bad,'overlap range')
bad=p;bad%code(c2)%items=[p%code(c2)%items(2),p%code(c2)%items(1)]
call validate_scalar_session_program(bad,d);call check(d%code==0,'reversed empty range admitted')
bad=p;bad%code(c1)%items=[p%code(a)%a,p%code(a)%a];call reject(bad,'variable range bound')
bad=p;bad%code(a)%items=[1];call reject(bad,'select hidden items')
! Failed admission must preserve existing healthy state/frontier.
bad=p;bad%code(c1)%a=c2
call execute_scalar_session(s,bad,d);call check(d%code/=0,'execute rejects forged owner')
call check(.not.scalar_session_tainted(s).and.scalar_session_frontier(s)==fr,'reject preserves healthy frontier')
d=diagnostic_t();call inspect_scalar_session(s,2,v,defined,d);call check(defined.and.v%i==20,'reject preserves value')
! Nested IF, SELECT and counted-loop boundaries.
call parse('program p'//nl//'integer :: i,n'//nl//'n=0'//nl//'do i=1,2'//nl// &
 'select case(i)'//nl//'case(1)'//nl//'if (i==1) then'//nl//'n=n+1'//nl//'end if'//nl// &
 'select case(i)'//nl//'case(1)'//nl//'n=n+2'//nl//'end select'//nl// &
 'case default'//nl//'n=n+4'//nl//'end select'//nl//'end do'//nl//'end program',q)
call validate_scalar_session_program(q,d);call check(d%code==0,'nested baseline')
a=0;inner=0;br=0;loop=0
 do j=1,q%nc
  if(q%code(j)%op==op_select)then
   if(a==0)then
    a=j
   else
    inner=j
   end if
  end if
  if(q%code(j)%op==op_branch)br=j
  if(q%code(j)%op==op_do)loop=j
 end do
call check(min(a,inner,br,loop)>0,'nested anchors')
bad=q;bad%code(br)%target=q%code(a)%target;call reject(bad,'IF crosses select arm')
bad=q;bad%code(br)%target=inner+2;call reject(bad,'IF enters nested select')
bad=q;bad%code(inner)%target=q%code(a)%target;call reject(bad,'inner select steals outer finish')
bad=q;bad%code(a)%target=q%code(loop)%target;call reject(bad,'select crosses loop NEXT')
bad=q;bad%code(loop)%target=q%code(inner)%target;call reject(bad,'loop ends inside select')
call reset_scalar_session(s);d=diagnostic_t();call execute_scalar_session(s,q,d)
call check(d%code==0,'nested execute')
call inspect_scalar_session(s,2,v,defined,d);call check(defined.and.v%i==7,'nested final value')
! Endpoint type compatibility and forged declared-vs-evaluated types.
call parse('program p'//nl// 'integer :: i'//nl//'select case(i)'//nl//'case(1+2)'//nl//'end select'//nl//'end program',p)
c1=0;idx=0
 do j=1,p%nc
  if(p%code(j)%op==op_case)c1=j
 end do
idx=p%code(c1)%items(1)
call check(p%expressions(idx)%kind==ex_binary,'constant arithmetic root retained')
call validate_scalar_session_program(p,d);call check(d%code==0,'integer constant DAG admitted')
bad=p;bad%expressions(idx)%typ=ty_character;bad%expressions(idx)%character_len=1
call reject(bad,'integer arithmetic forged CHARACTER metadata')
bad=p;bad%expressions(idx)%typ=ty_logical
call reject(bad,'integer arithmetic forged LOGICAL metadata')
! Repeated shared child amplifies work exponentially unless depth/visit bounded.
bad=p
 do j=1,34
  k=bad%ne+1
  bad%expressions(k)=expr_t(kind=ex_binary,typ=ty_integer,real_kind=4)
  bad%expressions(k)%left=bad%ne;bad%expressions(k)%right=bad%ne
  bad%expressions(k)%op='+';bad%ne=k
 end do
bad%code(c1)%items=[bad%ne,bad%ne];call reject(bad,'shared DAG exceeds recursion/visit budget')
call parse('program p'//nl// "character(len=2) :: c"//nl//"select case(c)"//nl//"case('a'//'b')"//nl// &
 'end select'//nl//'end program',p)
call reject(p,'CHARACTER concatenation bounds deliberately unsupported')
c1=0
 do j=1,p%nc
  if(p%code(j)%op==op_case)c1=j
 end do
idx=p%code(c1)%items(1)
bad=p;bad%expressions(idx)%typ=ty_integer;bad%expressions(idx)%character_len=-1
! Retag selector and its symbol as INTEGER so endpoint declared types agree.
 do j=1,bad%nc
  if(bad%code(j)%op/=op_select)cycle
  k=bad%code(j)%a
  bad%expressions(k)%typ=ty_integer;bad%expressions(k)%character_len=-1
  bad%symbols(bad%expressions(k)%symbol)%typ=ty_integer
  bad%symbols(bad%expressions(k)%symbol)%character_len=-1
 end do
call reject(bad,'CHARACTER evaluation forged INTEGER metadata')
! Reused literal endpoints count toward aggregate evaluated-byte budget.
call parse('program p'//nl//"character :: c"//nl//"select case(c)"//nl// &
 "case('x')"//nl//'end select'//nl//'end program',p)
a=0;c1=0
 do j=1,p%nc
  if(p%code(j)%op==op_select)a=j
  if(p%code(j)%op==op_case)c1=j
 end do
call check(a==1.and.p%nc==3,'minimal character select layout')
idx=p%code(c1)%items(1)
p%expressions(idx)%value%s=repeat('x',65536);p%expressions(idx)%character_len=65536
bad=p
 do j=1,129
  k=(j-1)*3
  bad%code(k+1:k+3)=p%code(1:3)
  bad%code(k+1)%target=k+4
  bad%code(k+2)%a=k+1;bad%code(k+2)%target=k+4
  bad%code(k+3)%target=k+4
 end do
bad%nc=384;d=diagnostic_t();call validate_scalar_session_program(bad,d)
call check(d%code==0,'128 reused 64KiB endpoint pairs within 16MiB budget')
bad%nc=387;call reject(bad,'129 reused endpoint pairs exceed 16MiB budget')
! Build canonical nested ownership directly, bypassing parser nesting limits.
call parse('program p'//nl//'integer :: i'//nl//'select case(i)'//nl// &
 'case(1)'//nl//'end select'//nl//'end program',p)
do depth=64,65
 bad=p
 do j=1,depth
  k=2*j-1
  bad%code(k)=p%code(1);bad%code(k)%target=3*depth-j+2
  bad%code(k+1)=p%code(2);bad%code(k+1)%a=k;bad%code(k+1)%target=3*depth-j+2
  bad%code(3*depth-j+1)=p%code(3);bad%code(3*depth-j+1)%target=3*depth-j+2
 end do
 bad%nc=3*depth;d=diagnostic_t();call validate_scalar_session_program(bad,d)
 call check((d%code==0).eqv.(depth==64),'SELECT nesting depth64 boundary')
end do
! CHARACTER concatenation must also be excluded below non-CHARACTER roots.
call parse('program p'//nl//'logical :: l'//nl//'select case(l)'//nl// &
 "case(('a'//'b')=='ab')"//nl//'end select'//nl//'end program',p)
call reject(p,'nested CHARACTER concatenation under LOGICAL bound')
bad=p
do j=1,bad%ne
 if(bad%expressions(j)%kind/=ex_binary.or.bad%expressions(j)%op/='//')cycle
 bad%expressions(j)%typ=ty_integer;bad%expressions(j)%character_len=-1
end do
call reject(bad,'forged INTEGER concat below LOGICAL root')
print *, 'independent SELECT mutation checks:',checks
contains
subroutine parse(src,out)
character(*),intent(in)::src
type(program_t),intent(out)::out
d=diagnostic_t();call parse_subset(src//nl,out,d);call check(d%code==0,'parse source')
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
