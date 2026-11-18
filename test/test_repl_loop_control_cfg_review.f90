program test_loop_control_cfg_review
use, intrinsic::iso_fortran_env,only:int64
use fi_ir
use fi_parser,only:parse_subset
use fi_runtime
implicit none
character(*),parameter::nl=new_line('a')
character(*),parameter::head='program p'//nl//'integer :: i,j,n'//nl
character(:),allocatable::body
 type(program_t)::p,q,bad
 type(scalar_session_t)::s,t
 type(diagnostic_t)::d
 type(value_t)::v
 logical::defined
 integer::checks=0,j,k,outer,inner,bare,cyc,ex,nextouter,firstwhile,frontier
 character(20)::labels(7)
body='n=0'//nl//'outer: do i=1,3'//nl//'inner: do j=1,2'//nl//'do'//nl// &
 'n=n+1'//nl//'if (j==1) cycle outer'//nl//'exit inner'//nl//'end do'//nl// &
 'end do inner'//nl//'end do outer'//nl//'do j=1,2'//nl//'n=n+1'//nl//'end do'//nl
call parse(head//body,p)
call validate_scalar_session_program(p,d);call check(d%code==0,'mixed named baseline admission')
call execute_scalar_session(s,p,d);call check(d%code==0,'named cycle unwinds counted and bare inner controls')
call inspect_scalar_session(s,3,v,defined,d);call check(defined.and.v%i==5,'named cycle and index reuse value')
call inspect_scalar_session(s,2,v,defined,d);call check(v%i==3,'inner counted index reusable after outer cycle')
outer=0;inner=0;bare=0;cyc=0;ex=0
do j=1,p%nc
 if(p%code(j)%op==op_do.and.p%code(j)%construct_name=='outer')outer=j
 if(p%code(j)%op==op_do.and.p%code(j)%construct_name=='inner')inner=j
 if(p%code(j)%op==op_do.and.p%code(j)%d==1)bare=j
 if(p%code(j)%op==op_cycle)cyc=j
 if(p%code(j)%op==op_exit)ex=j
end do
call check(outer>0.and.inner>0.and.bare>0.and.cyc>0.and.ex>0,'control nodes located')
nextouter=p%code(outer)%target-1
! Named and unnamed transfer identity: destination PCs alone do not authorize a jump.
bad=p;bad%code(cyc)%construct_name='inner';call reject(bad,'cycle name disagrees with anchor')
bad=p;bad%code(cyc)%construct_name='';call reject(bad,'unnamed cycle cannot select outer')
bad=p;bad%code(ex)%construct_name='';call reject(bad,'unnamed exit must select nearest bare owner')
bad=p;bad%code(ex)%a=outer;bad%code(ex)%target=p%code(outer)%target;call reject(bad,'exit name disagrees with outer anchor')
bad=p;bad%code(cyc)%target=p%code(outer)%target;call reject(bad,'cycle cannot use exit destination')
bad=p;bad%code(ex)%target=p%code(inner)%target-1;call reject(bad,'exit cannot use cycle destination')
bad=p;bad%code(ex)%symbol=1;call reject(bad,'transfer hidden symbol')
bad=p;bad%code(cyc)%d=1;call reject(bad,'transfer hidden mode')
bad=p;bad%code(bare)%symbol=1;call reject(bad,'bare loop symbol must zero')
bad=p;bad%code(bare)%a=p%code(outer)%a;call reject(bad,'bare loop hidden condition')
bad=p;bad%code(nextouter)%construct_name='inner';call reject(bad,'NEXT owner name mismatch')
! For every transfer target, only its exact prescribed destination is accepted.
do j=1,p%nc
 if(p%code(j)%op/=op_exit.and.p%code(j)%op/=op_cycle)cycle
 do k=0,p%nc+2
  bad=p;bad%code(j)%target=k;d=diagnostic_t();call validate_scalar_session_program(bad,d)
  call check((d%code==0).eqv.(k==p%code(j)%target),'transfer destination exhaustive')
 end do
end do
! Distinct source construct names are global within the single admitted scope.
bad=p
bad%code(inner)%construct_name='outer';bad%code(p%code(inner)%target-1)%construct_name='outer'
call reject(bad,'duplicate active construct name')
do j=nextouter+1,p%nc
 if(p%code(j)%op/=op_do)cycle
 bad=p;bad%code(j)%construct_name='outer';bad%code(p%code(j)%target-1)%construct_name='outer'
 call reject(bad,'duplicate disjoint construct name')
end do
! Reserved source names cannot be laundered through otherwise matching anchors.
labels=[character(20)::'if','abs','enddo','random_number','integer','Outer','bad name']
do k=1,size(labels)
 bad=p
 do j=1,bad%nc
  if(bad%code(j)%construct_name=='outer')bad%code(j)%construct_name=labels(k)
 end do
 call reject(bad,'reserved or malformed construct name')
end do
! Two intentionally nonreserved names stay usable in this prototype.
do k=1,2
 bad=p
 do j=1,bad%nc
  if(bad%code(j)%construct_name/='outer')cycle
  if(k==1)bad%code(j)%construct_name='char'
  if(k==2)bad%code(j)%construct_name='procedure'
 end do
 d=diagnostic_t();call validate_scalar_session_program(bad,d)
 call check(d%code==0,'nonreserved contextual construct name')
end do
! Closed loops remain appendable and queries do not repeat completed transfers.
frontier=scalar_session_frontier(s);t=s
call parse(head//body//'do while (n<8)'//nl//'n=n+1'//nl//'end do'//nl,q)
call execute_scalar_session(s,q,d);call check(d%code==0,'appended while')
call inspect_scalar_session(s,3,v,defined,d);call check(v%i==8,'appended while no replay')
call execute_scalar_session(s,q,d);call inspect_scalar_session(s,3,v,defined,d);call check(v%i==8,'empty suffix no replay')
call inspect_scalar_session(t,3,v,defined,d);call check(v%i==5,'loop control clone independent')
call parse(head//body//'do while (n<8)'//nl//'n=n+1'//nl//'end do'//nl//'print *,n'//nl,p)
call execute_scalar_session(s,p,d,commit=.false.);call check(d%code==0,'query after loop controls')
call execute_scalar_session(s,p,d,commit=.false.);call check(d%code==0,'repeated query after loop controls')
! Zero-symbol bare/WHILE sessions exercise d1/d2 without indexing active_index(0).
call reset_scalar_session(s)
call parse('program p'//nl//'do'//nl//'exit'//nl//'end do'//nl//'do while (.false.)'//nl//'end do'//nl,p)
call execute_scalar_session(s,p,d);call check(d%code==0,'no-symbol loop forms')
! Declaration growth after closed EXIT must preserve exact loop metadata/frontier.
call parse('program p'//nl//'integer :: added'//nl//'do'//nl//'exit'//nl//'end do'//nl// &
 'do while (.false.)'//nl//'end do'//nl,q)
frontier=scalar_session_frontier(s)
call grow_scalar_session(s,p,q,2,d);call check(d%code==0,'growth after no-symbol loop controls')
call check(scalar_session_frontier(s)==frontier,'growth loop frontier unchanged')
call execute_scalar_session(s,q,d);call check(d%code==0,'exact loop snapshot after growth')
call inspect_scalar_session(s,1,v,defined,d);call check(.not.defined,'new variable remains undefined')
! WHILE condition canonical metadata and legitimate false entry.
call reset_scalar_session(s)
call parse(head//'n=0'//nl//'w: do while(n<2)'//nl//'n=n+1'//nl//'end do w'//nl,p)
firstwhile=0
do j=1,p%nc
 if(p%code(j)%op==op_do)firstwhile=j
end do
bad=p;bad%code(firstwhile)%symbol=1;call reject(bad,'while hidden index')
bad=p;bad%code(firstwhile)%b=1;call reject(bad,'while hidden upper bound')
bad=p;bad%code(firstwhile)%c=1;call reject(bad,'while hidden step')
bad=p;bad%expressions(bad%code(firstwhile)%a)%real_kind=8;call reject(bad,'while logical kind')
call execute_scalar_session(s,p,d);call check(d%code==0,'while re-evaluation')
call inspect_scalar_session(s,3,v,defined,d);call check(v%i==2,'while final value')
! Infinite but structurally valid cycles terminate under the step budget and taint.
call reset_scalar_session(s)
call parse('program p'//nl//'do'//nl//'cycle'//nl//'end do'//nl,p)
call execute_scalar_session(s,p,d,max_steps=50_int64)
call check(d%code/=0.and.scalar_session_tainted(s),'bare cycle budget taints')
print *, 'independent loop control CFG checks:',checks
contains
subroutine parse(src,p)
character(*),intent(in)::src
type(program_t),intent(out)::p
d=diagnostic_t();call parse_subset(src//'end program p'//nl,p,d);call check(d%code==0,'parse')
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
subroutine reject(bad,label)
type(program_t),intent(in)::bad
character(*),intent(in)::label
d=diagnostic_t();call validate_scalar_session_program(bad,d);call check(d%code/=0,label)
d=diagnostic_t()
end subroutine
end program
