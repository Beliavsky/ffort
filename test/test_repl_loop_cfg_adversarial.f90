program test_loop_cfg_review
use, intrinsic::iso_fortran_env,only:int64
use fi_ir
use fi_parser,only:parse_subset
use fi_runtime
implicit none
character(*),parameter::nl=new_line('a')
character(*),parameter::head='program p'//nl//'integer :: i,j,n'//nl
character(:),allocatable::body
 type(program_t)::p,q,bad
 type(diagnostic_t)::d
 type(scalar_session_t)::s,t
 type(value_t)::v
 logical::defined,want
 integer::j,k,checks=0,accepted=0,owners(100),depth,stack(100),loop1,next1,loop2,next2,branch
body='n=0'//nl//'do i=1,2'//nl//'if (.true.) n=n+1'//nl// &
 'do j=1,2'//nl//'n=n+1'//nl//'end do'//nl//'end do'//nl// &
 'do j=1,2'//nl//'n=n+1'//nl//'end do'//nl
call parse(body,p)
call validate_scalar_session_program(p,d);call check(d%code==0,'baseline admission')
loop1=0;loop2=0;branch=0
owners=0;depth=0
! Independent target expectation from lexical interval containment.
do j=1,p%nc
 if(p%code(j)%op==op_do)then
  if(loop1==0)then
   loop1=j;next1=p%code(j)%target-1
  else if(loop2==0)then
   loop2=j;next2=p%code(j)%target-1
  end if
  owners(j+1:p%code(j)%target-1)=j
 end if
 if(p%code(j)%op==op_branch)branch=j
end do
! Every possible forward branch target: only same exact lexical owner is safe.
do k=branch+1,p%nc+1
 bad=p;bad%code(branch)%target=k;d=diagnostic_t()
 call validate_scalar_session_program(bad,d)
 want=owners(k)==owners(branch)
 call check((d%code==0).eqv.want,'branch owner target exhaustive')
 if(want)then
  accepted=accepted+1;call reset_scalar_session(t)
  call execute_scalar_session(t,bad,d,max_steps=10000_int64)
  call check(d%code==0,'accepted forward CFG executes')
 end if
end do
! A forged forward JUMP inside the loop follows the same owner rule.
do k=branch+1,p%nc+1
 bad=p;bad%code(branch)=instruction_t(op=op_jump,target=k)
 d=diagnostic_t();call validate_scalar_session_program(bad,d)
 call check((d%code==0).eqv.(owners(k)==owners(branch)),'jump owner target exhaustive')
end do
! Exhaustive DO exit and NEXT owner/backedge corruption on both nested loops.
do j=1,p%nc
 if(p%code(j)%op==op_do)then
  do k=0,p%nc+2
   bad=p;bad%code(j)%target=k;d=diagnostic_t()
   call validate_scalar_session_program(bad,d)
   call check((d%code==0).eqv.(k==p%code(j)%target),'DO exit target exhaustive')
  end do
 else if(p%code(j)%op==op_next)then
  do k=0,p%nc+2
   bad=p;bad%code(j)%a=k;d=diagnostic_t()
   call validate_scalar_session_program(bad,d)
   call check((d%code==0).eqv.(k==p%code(j)%a),'NEXT owner exhaustive')
   bad=p;bad%code(j)%target=k;d=diagnostic_t()
   call validate_scalar_session_program(bad,d)
   call check((d%code==0).eqv.(k==p%code(j)%target),'NEXT backedge exhaustive')
  end do
 end if
end do
bad=p;bad%code(loop1)%construct_name='named';call reject(bad,'named DO excluded')
! Cross-loop pairing, NEXT identity, inactive fields, active index writes.
bad=p;bad%code(next1)%a=loop2;call reject(bad,'cross paired NEXT')
bad=p;bad%code(next2)%a=loop1;call reject(bad,'inner NEXT outer owner')
bad=p;bad%code(loop2)%target=p%code(loop1)%target;call reject(bad,'crossed interval')
bad=p;bad%code(next1)%target=1;call reject(bad,'NEXT rewinds old prefix')
bad=p;bad%code(loop1)%d=1;call reject(bad,'bare form excluded')
bad=p;bad%code(loop1)%d=2;call reject(bad,'while form excluded')
bad=p;bad%code(loop1)%items=[1];call reject(bad,'hidden DO payload')
bad=p;bad%code(next1)%b=1;call reject(bad,'hidden NEXT payload')
bad=p;bad%code(loop2)%symbol=1;bad%code(next2)%symbol=1;call reject(bad,'active index reuse')
bad=p;bad%code(loop2+1)%symbol=1;call reject(bad,'write outer active index')
bad=p;bad%code(loop2+1)%symbol=2;call reject(bad,'write inner active index')
! Old snapshot remains exact; suffix and readonly probes cannot restart loops.
d=diagnostic_t();call execute_scalar_session(s,p,d);call check(d%code==0,'retained baseline')
call inspect_scalar_session(s,3,v,defined,d);call check(defined.and.v%i==8,'baseline sum')
t=s
call parse(body//'do i=1,2'//nl//'n=n+1'//nl//'end do'//nl,q)
call execute_scalar_session(s,q,d);call check(d%code==0,'appended closed loop')
call inspect_scalar_session(s,3,v,defined,d);call check(v%i==10,'no replay suffix')
call execute_scalar_session(s,q,d)
call inspect_scalar_session(s,3,v,defined,d);call check(v%i==10,'empty suffix no replay')
call inspect_scalar_session(t,3,v,defined,d);call check(v%i==8,'session clone independence')
call parse(body//'do i=1,2'//nl//'n=n+1'//nl//'end do'//nl//'print *,n'//nl,p)
call execute_scalar_session(s,p,d,commit=.false.);call check(d%code==0,'readonly query after loop')
call execute_scalar_session(s,p,d,commit=.false.);call check(d%code==0,'repeat readonly query')
bad=p;bad%code(loop1)%target=bad%nc+1
d=diagnostic_t();call execute_scalar_session(s,bad,d,commit=.false.)
call check(d%code/=0.and..not.scalar_session_tainted(s),'query exit bypass rejects without taint')
print *, 'independent loop CFG checks:',checks,'admitted target variants:',accepted
contains
subroutine parse(text,p)
character(*),intent(in)::text
type(program_t),intent(out)::p
d=diagnostic_t();call parse_subset(head//text//'end program p'//nl,p,d)
call check(d%code==0,'parse')
end subroutine
subroutine reject(bad,name)
type(program_t),intent(in)::bad
character(*),intent(in)::name
d=diagnostic_t();call validate_scalar_session_program(bad,d)
call check(d%code/=0,name)
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
