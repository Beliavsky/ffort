program test_loop_forms_independent
use,intrinsic::iso_fortran_env,only:int64
use fi_ir
use fi_parser,only:parse_subset
use fi_runtime
implicit none
character(*),parameter::nl=new_line('a')
character(*),parameter::head='program p'//nl//'integer :: i,j,k,s,a(2)'//nl
character(*),parameter::prefix='s=77'//nl
character(*),parameter::body='s=0'//nl//'i=0'//nl//'outer: do while(i<3)'//nl// &
 'i=i+1'//nl//'inner: do j=1,3'//nl//'if(j==2) cycle inner'//nl//'s=s+1'//nl// &
 'if(i==2) exit outer'//nl//'end do inner'//nl//'end do outer'//nl//'j=9'//nl// &
 'k=0'//nl//'do'//nl//'k=k+1'//nl//'if(k==2) exit'//nl//'enddo'//nl// &
 'a=2'//nl//'do while(sum(a)>0)'//nl//'a=a-1'//nl//'enddo'//nl
character(63),parameter::names(6)=[character(63)::'','outer','inner','missing','OUTER','bad-name']
type(program_t)::p,bad,base,q,grown
 type(diagnostic_t)::d
 type(scalar_session_t)::session,copy,trial
 type(value_t)::v
 logical::defined,want
 integer::checks=0,jj,kk,ll,pc,npc,outer,inner,cyclepc,exitpc,do3,target,which,frontier,idx(3),forms(3),form
call parse_subset(head//prefix//'end program'//nl,base,d);call check(d%code==0,'parse base')
call execute_scalar_session(session,base,d);call check(d%code==0,'execute base');copy=session
frontier=scalar_session_frontier(copy)
call parse_subset(head//prefix//body//'end program'//nl,p,d);call check(d%code==0,'parse fixture')
call validate_scalar_session_program(p,d);call check(d%code==0,'fixture admitted')
outer=0;inner=0;do3=0;cyclepc=0;exitpc=0
 do pc=1,p%nc
  if(p%code(pc)%op==op_do)then
   if(p%code(pc)%construct_name=='outer')outer=pc
   if(p%code(pc)%construct_name=='inner')inner=pc
   if(p%code(pc)%d==1)do3=pc
  end if
  if(p%code(pc)%op==op_cycle)cyclepc=pc
  if(p%code(pc)%op==op_exit.and.p%code(pc)%construct_name=='outer')exitpc=pc
 end do
call check(min(outer,inner,do3,cyclepc,exitpc)>0,'fixture identities')
idx=[outer,inner,do3]
! Every selected loop/name/target triple for two transfers inside INNER.
do which=1,2
 pc=cyclepc;if(which==2)pc=exitpc
 do jj=1,3
  do kk=1,size(names)
   do target=0,p%nc+2
    bad=p;bad%code(pc)%a=idx(jj);bad%code(pc)%construct_name=names(kk);bad%code(pc)%target=target
    want=.false.
    if(jj<=2)then
     if(len_trim(names(kk))==0)then
      want=idx(jj)==inner
     else
      want=names(kk)==p%code(idx(jj))%construct_name
     end if
     npc=p%code(idx(jj))%target;if(which==1)npc=npc-1
     want=want.and.target==npc
    end if
    d=diagnostic_t();call validate_scalar_session_program(bad,d)
    call check((d%code==0).eqv.want,'ancestor/name/destination triple')
    if(.not.want)then
     trial=copy;d=diagnostic_t();call execute_scalar_session(trial,bad,d)
     call check(d%code/=0.and..not.scalar_session_tainted(trial),'bad transfer rejected untainted')
     call check(scalar_session_frontier(trial)==frontier,'bad transfer frontier')
    end if
   end do
  end do
 end do
end do
! Arbitrary inactive payloads and pair form/name changes are not accepted.
do jj=1,14
 bad=p
 select case(jj)
 case(1);bad%code(cyclepc)%symbol=1
 case(2);bad%code(exitpc)%d=2
 case(3);bad%code(cyclepc)%b=1
 case(4);bad%code(exitpc)%third=1
 case(5);allocate(bad%code(exitpc)%items(0))
 case(6);bad%code(outer)%b=1
 case(7);bad%code(do3)%a=1
 case(8);bad%code(outer)%symbol=1
 case(9);bad%code(p%code(outer)%target-1)%d=0
 case(10);bad%code(p%code(inner)%target-1)%construct_name='outer'
 case(11);bad%code(outer)%construct_name='OUTER';bad%code(p%code(outer)%target-1)%construct_name='OUTER'
 case(12);bad%code(inner)%construct_name='outer';bad%code(p%code(inner)%target-1)%construct_name='outer'
 case(13)
  bad%code(outer)%construct_name='do';bad%code(p%code(outer)%target-1)%construct_name='do'
  bad%code(exitpc)%construct_name='do'
 case(14)
  bad%code(outer)%construct_name='abs';bad%code(p%code(outer)%target-1)%construct_name='abs'
  bad%code(exitpc)%construct_name='abs'
 end select
 d=diagnostic_t();call validate_scalar_session_program(bad,d);call check(d%code/=0,'inactive/pair/name mutation')
end do
! Execute full fixture and confirm old prefix is skipped, outer exit releases J.
trial=copy;d=diagnostic_t();call execute_scalar_session(trial,p,d);call check(d%code==0,'execute retained forms')
call inspect_scalar_session(trial,4,v,defined,d);call check(defined.and.v%i==3,'outer exit result')
call inspect_scalar_session(trial,2,v,defined,d);call check(defined.and.v%i==9,'released counted variable')
call inspect_scalar_session(trial,3,v,defined,d);call check(defined.and.v%i==2,'bare exit result')
call execute_scalar_session(trial,p,d);call check(d%code==0,'no suffix replay')
bad=p;bad%code(exitpc)%a=inner;bad%code(exitpc)%target=p%code(inner)%target
bad%code(exitpc)%construct_name='inner'
d=diagnostic_t();call validate_scalar_session_program(bad,d)
call check(d%code==0,'retargeted prefix locally valid')
call execute_scalar_session(trial,bad,d)
call check(d%code/=0.and..not.scalar_session_tainted(trial),'changed committed transfer rejects without taint')
d=diagnostic_t();call inspect_scalar_session(trial,4,v,defined,d)
call check(d%code==0.and.defined.and.v%i==3,'changed prefix preserved value')
call check(scalar_session_frontier(trial)==p%nc+1,'changed prefix preserved frontier')

! Plain scalar growth must map names/control targets without executing loops.
call parse_subset(head//'real :: fresh'//nl//prefix//body//'end program'//nl,grown,d)
call check(d%code==0,'parse grown fixture')
call grow_scalar_session(trial,p,grown,3,d);call check(d%code==0,'growth after named outer exit')
call inspect_scalar_session(trial,6,v,defined,d);call check(d%code==0.and..not.defined,'fresh undefined')
call execute_scalar_session(trial,grown,d);call check(d%code==0,'grown loop prefix exact')
call inspect_scalar_session(trial,4,v,defined,d);call check(v%i==3,'growth no replay')
print *, 'independent loop-form checks:',checks
contains
subroutine check(ok,label)
 logical,intent(in)::ok
 character(*),intent(in)::label
 checks=checks+1
 if(.not.ok)then
  print *, 'FAILED ',label
  if(allocated(d%message))print *,d%message
  stop 1
 end if
end subroutine
end program
