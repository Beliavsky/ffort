program test_repl_scalar_growth
use, intrinsic::iso_fortran_env,only:int64
use fi_ir
use fi_parser,only:parse_subset
use fi_runtime
implicit none
character(*),parameter::nl=new_line('a')
character(*),parameter::head='program p'//nl//'implicit none'//nl//'integer :: i,u,a(-1:1)'//nl// &
 'real :: x'//nl//'character(12) :: text'//nl
character(:),allocatable::body,pending
 type(program_t)::old,original,candidate,next,bad
 type(scalar_session_t)::s,copy,baseline,trial,fresh
 type(diagnostic_t)::d
 type(value_t)::v,w
 type(value_t),allocatable::av(:)
 logical,allocatable::flags(:)
 logical::defined
 integer(int64)::lo,oldrng
 integer::j,k,checks=0,frontier
body='i=7'//nl//'a(-1)=3'//nl//'text="MiXeD Case"'//nl//'call random_seed()'//nl// &
 'call random_number(x)'//nl//'do i=1,2'//nl//'a(-1)=a(-1)+1'//nl//'end do'//nl
pending='call random_number(x)'//nl//'i=i+10'//nl
call parse(head//body,old)
call execute_scalar_session(s,old,d);call check(d%code==0,'baseline execute')
frontier=scalar_session_frontier(s);baseline=s
call inspect_scalar_session(s,4,v,defined,d);oldrng=transfer(v%r,0_int64)
call parse(head//body//pending,original)
call parse(head//'integer :: fresh'//nl//body//pending,candidate)
! Incoming error, invalid injection arguments and every allocation staging failure.
do j=1,4
 trial=s;d=diagnostic_t()
 call grow_scalar_session(trial,original,candidate,6,d,fail_allocation_at=j)
 call check(d%code/=0.and..not.scalar_session_tainted(trial),'injected staging failure')
 call unchanged(trial,'fault rollback')
 d=diagnostic_t();call execute_scalar_session(trial,old,d)
 call check(d%code==0.and.scalar_session_frontier(trial)==frontier,'fault leaves exact original snapshot')
end do
trial=s;d=diagnostic_t();d%code=1
call grow_scalar_session(trial,original,candidate,6,d)
call check(d%code==1,'incoming diag preserved');call unchanged(trial,'incoming error rollback')
do j=-1,5
 if(j>=1.and.j<=4)cycle
 trial=s;d=diagnostic_t();call grow_scalar_session(trial,original,candidate,6,d,fail_allocation_at=j)
 call check(d%code/=0,'invalid injection rejected');call unchanged(trial,'invalid injection rollback')
end do
! No execution during growth: pending RNG/assignment must remain pending.
d=diagnostic_t();call grow_scalar_session(s,original,candidate,6,d)
call check(d%code==0,'growth succeeds')
call unchanged(s,'growth preserves old state')
call inspect_scalar_session(s,6,v,defined,d);call check(d%code==0.and..not.defined,'new scalar undefined')
copy=s
call execute_scalar_session(s,candidate,d);call check(d%code==0,'pending suffix after growth')
call execute_scalar_session(baseline,original,d);call check(d%code==0,'old-layout baseline suffix')
call inspect_scalar_session(s,4,v,defined,d);call inspect_scalar_session(baseline,4,w,defined,d)
call check(transfer(v%r,0_int64)==transfer(w%r,0_int64),'RNG unchanged by growth')
call inspect_scalar_session(s,1,v,defined,d);call check(v%i==13,'pending suffix executed once')
call execute_scalar_session(s,candidate,d);call inspect_scalar_session(s,1,v,defined,d)
call check(v%i==13,'empty suffix no replay')
call inspect_scalar_session(copy,1,v,defined,d);call check(v%i==3,'clone unaffected by suffix')
! Second growth appends a LOGICAL scalar; original growth stays defined independently.
call parse(head//'integer :: fresh'//nl//body//pending//'fresh=42'//nl,original)
call execute_scalar_session(s,original,d);call check(d%code==0,'fresh assignment')
call parse(head//'integer :: fresh'//nl//'logical :: flag'//nl//body//pending//'fresh=42'//nl,candidate)
frontier=scalar_session_frontier(s)
call grow_scalar_session(s,original,candidate,7,d);call check(d%code==0,'repeated growth')
call check(scalar_session_frontier(s)==frontier,'repeated growth frontier')
call inspect_scalar_session(s,6,v,defined,d);call check(defined.and.v%i==42,'earlier added scalar retained')
call inspect_scalar_session(s,7,v,defined,d);call check(.not.defined,'second added scalar undefined')
call parse(head//'integer :: fresh'//nl//'logical :: flag'//nl//body//pending//'fresh=42'//nl// &
 'flag=.true.'//nl//'a(0)=fresh'//nl,next)
call execute_scalar_session(s,next,d);call check(d%code==0,'postgrowth execution')
call inspect_session_array(s,3,av,flags,lo,d)
call check(all(flags(:2)).and..not.flags(3).and.av(1)%i==5.and.av(2)%i==42,'owned array flags retained')
! Empty session established by literal-only query has no declarations to freeze forever.
call parse('program p'//nl//'implicit none'//nl,old)
call execute_scalar_session(fresh,old,d);call check(d%code==0,'ready empty')
call parse('program p'//nl//'implicit none'//nl//'print *,2+2'//nl,next)
call execute_scalar_session(fresh,next,d,commit=.false.);call check(d%code==0,'literal readonly query')
call parse('program p'//nl//'implicit none'//nl//'real :: first'//nl,candidate)
call grow_scalar_session(fresh,old,candidate,3,d);call check(d%code==0,'growth after empty query')
call inspect_scalar_session(fresh,1,v,defined,d);call check(.not.defined,'first variable undefined')
! A declaration-only retained buffer also grows without instructions or replay.
call reset_scalar_session(trial)
call parse('program p'//nl//'implicit none'//nl//'integer :: untouched'//nl,old)
call execute_scalar_session(trial,old,d);call check(d%code==0,'declaration only ready')
call parse('program p'//nl//'implicit none'//nl//'integer :: untouched'//nl//'logical :: added'//nl,candidate)
call grow_scalar_session(trial,old,candidate,4,d);call check(d%code==0,'declaration only growth')
call inspect_scalar_session(trial,1,v,defined,d);call check(.not.defined,'old declaration stays undefined')
call inspect_scalar_session(trial,2,v,defined,d);call check(.not.defined,'new declaration stays undefined')
! Adversarial failures use pristine pre-growth session and complete buffer.
s=copy
call parse(head//body,old)
call parse(head//body//pending,original)
call parse(head//'integer :: fresh'//nl//body//pending,candidate)
! COPY already has one growth, so use a fresh baseline with original namespace.
call reset_scalar_session(s);call execute_scalar_session(s,old,d)
frontier=scalar_session_frontier(s);call inspect_scalar_session(s,4,v,defined,d);oldrng=transfer(v%r,0_int64)
bad=candidate;bad%symbols(6)%real_kind=8;call reject(original,bad,6,'kind8')
bad=candidate;bad%symbols(6)%kind_expr=1;call reject(original,bad,6,'explicit kind selector')
bad=candidate;bad%symbols(6)%is_saved=.true.;call reject(original,bad,6,'attribute')
bad=candidate;bad%symbols(6)%initializer_expr=1;call reject(original,bad,6,'initializer')
bad=candidate;bad%symbols(6)%name='i';call reject(original,bad,6,'duplicate name')
bad=candidate;bad%symbols(6)%name='I';call reject(original,bad,6,'case normalized duplicate name')
bad=candidate;bad%symbols(6)%name='bad-name';call reject(original,bad,6,'invalid new name')
bad=candidate;bad%symbols(6)%name='';call reject(original,bad,6,'blank new name')
bad=candidate;bad%symbols(6)%name='do';call reject(original,bad,6,'keyword new name')
bad=candidate;bad%symbols(6)%name='abs';call reject(original,bad,6,'reserved intrinsic new name')
bad=candidate;bad%symbols(6)%constant_value%i=1;call reject(original,bad,6,'hidden new symbol payload')
bad=candidate;bad%symbols(6)%line=7;call reject(original,bad,6,'new declaration line')
bad=candidate;bad%symbols(6)%column=0;call reject(original,bad,6,'new declaration column')
bad=candidate;bad%code(1)%column=bad%code(1)%column+1;call reject(original,bad,6,'changed code column')
bad=candidate;bad%code(1)%line=bad%code(1)%line+1;call reject(original,bad,6,'wrong line map')
bad=candidate;bad%code(1)%op=op_random_seed;call reject(original,bad,6,'changed opcode')
bad=candidate;bad%expressions(original%ne)%value%i=99;call reject(original,bad,6,'changed expression')
bad=candidate;bad%symbols(1)%column=bad%symbols(1)%column+1;call reject(original,bad,6,'changed old symbol')
call reject(original,candidate,0,'zero insertion')
call reject(original,candidate,huge(1),'overflow insertion')
call reject(original,candidate,7,'insertion after executable start')
bad=original;bad%code(1)%a=bad%code(2)%a;call reject(bad,candidate,6,'forged original snapshot prefix')
bad=original;bad%nc=bad%nc-1;call reject(bad,candidate,6,'candidate adds instructions')
bad=original;bad%code(bad%nc)%a=bad%code(1)%a;call reject(bad,candidate,6,'changed pending original')
bad=original;bad%expressions(bad%ne)%line=huge(1);call reject(bad,candidate,6,'pending line map overflow')
call parse(head//'integer :: fresh,second'//nl//body//pending,bad)
call reject(original,bad,6,'multiple new names')
call parse(head//'integer(4) :: fresh'//nl//body//pending,bad)
call reject(original,bad,6,'selector adds expression IDs')
! Zero diagnostic locations of direct-IR records remain exactly zero.
old=original
old%code(:old%nc)%line=0;old%expressions(:old%ne)%line=0;old%symbols(:old%ns)%line=0
call reset_scalar_session(trial);d=diagnostic_t();call execute_scalar_session(trial,old,d)
call check(d%code==0,'zero location baseline')
bad=candidate;bad%code(:bad%nc)%line=0;bad%expressions(:bad%ne)%line=0;bad%symbols(:old%ns)%line=0
call grow_scalar_session(trial,old,bad,6,d);call check(d%code==0,'zero locations preserved')
call execute_scalar_session(trial,bad,d);call check(d%code==0,'zero location exact prefix after growth')
! Fresh and tainted states cannot use this API.
call reset_scalar_session(trial);d=diagnostic_t();call grow_scalar_session(trial,original,candidate,6,d)
call check(d%code/=0.and..not.scalar_session_tainted(trial),'unready rejected without taint')
call parse(head//'i=1/u'//nl,old)
d=diagnostic_t();call execute_scalar_session(trial,old,d);call check(scalar_session_tainted(trial),'create taint')
d=diagnostic_t();call grow_scalar_session(trial,original,candidate,6,d)
call check(d%code/=0.and.scalar_session_tainted(trial),'tainted growth rejected')
print *, 'retained scalar growth checks:',checks
contains
subroutine parse(src,p)
character(*),intent(in)::src
type(program_t),intent(out)::p
d=diagnostic_t();call parse_subset(src//'end program p'//nl,p,d)
call check(d%code==0,'parse')
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
subroutine unchanged(state,label)
type(scalar_session_t),intent(in)::state
character(*),intent(in)::label
d=diagnostic_t()
call check(scalar_session_frontier(state)==frontier,label//' frontier')
call inspect_scalar_session(state,1,v,defined,d);call check(defined.and.v%i==3,label//' integer')
call inspect_scalar_session(state,2,v,defined,d);call check(.not.defined,label//' undefined scalar')
call inspect_scalar_session(state,4,v,defined,d);call check(transfer(v%r,0_int64)==oldrng,label//' RNG value')
call inspect_scalar_session(state,5,v,defined,d);call check(defined.and.v%s=='MiXeD Case  ',label//' CHARACTER')
call inspect_session_array(state,3,av,flags,lo,d)
call check(lo==-1.and.size(av)==3.and.flags(1).and..not.any(flags(2:)),label//' array flags')
call check(av(1)%i==5,label//' array value')
end subroutine
subroutine reject(orig,cand,line,label)
type(program_t),intent(in)::orig,cand
integer,intent(in)::line
character(*),intent(in)::label
trial=s;d=diagnostic_t();call grow_scalar_session(trial,orig,cand,line,d)
call check(d%code/=0.and..not.scalar_session_tainted(trial),label)
call unchanged(trial,label//' rollback')
end subroutine
end program
