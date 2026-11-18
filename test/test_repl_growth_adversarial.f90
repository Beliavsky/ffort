program test_growth_independent_native
use,intrinsic::iso_fortran_env,only:int64
use fi_ir
use fi_parser,only:parse_subset
use fi_runtime
implicit none
character(*),parameter::nl=new_line('a')
character(*),parameter::head='program p'//nl//'integer :: n'//nl//'character(len=3) :: s'//nl//'integer :: a(2)'//nl
character(*),parameter::body='n=7'//nl//"s='AbC'"//nl//'a(1)=3'//nl
character(*),parameter::tail='n=n+2'//nl//'end program'//nl
type(program_t)::base,original,candidate,bad,changed
 type(diagnostic_t)::d
 type(scalar_session_t)::s,copy,trial
 type(value_t)::v
 type(value_t),allocatable::av(:)
 logical,allocatable::flags(:)
 logical::defined
 integer(int64)::lo
 integer::checks=0,k,frontier
call parse_subset(head//body//'end program'//nl,base,d);call check(d%code==0,'parse base')
call execute_scalar_session(s,base,d);call check(d%code==0,'execute base')
copy=s;frontier=scalar_session_frontier(s)
call parse_subset(head//body//tail,original,d);call check(d%code==0,'parse pending')
call parse_subset(head//'real :: fresh'//nl//body//tail,candidate,d);call check(d%code==0,'parse candidate')
do k=1,4
 trial=copy;d=diagnostic_t();call grow_scalar_session(trial,original,candidate,5,d,k)
 call check(d%code/=0,'fault rejected');call unchanged(trial)
 d=diagnostic_t();call grow_scalar_session(trial,original,candidate,5,d)
 call check(d%code==0,'retry after fault');call inspect_scalar_session(trial,4,v,defined,d)
 call check(d%code==0.and..not.defined,'fresh undefined')
 d=diagnostic_t();call execute_scalar_session(trial,candidate,d)
 call check(d%code==0,'pending execution');call inspect_scalar_session(trial,1,v,defined,d)
 call check(defined.and.v%i==9,'pending runs once')
 call unchanged(copy)
end do
! All public allocations precede the ownership commit; incoming diagnostics no-op.
trial=copy;d%code=77;call grow_scalar_session(trial,original,candidate,5,d)
call check(d%code==77,'incoming diagnostic preserved');call unchanged(trial)
do k=1,24
 bad=candidate;changed=original
 select case(k)
 case(1);bad%symbols(1)%column=bad%symbols(1)%column+1
 case(2);bad%symbols(4)%line=bad%symbols(4)%line+1
 case(3);bad%symbols(4)%typ=ty_character
 case(4);bad%symbols(4)%real_kind=8
 case(5);bad%symbols(4)%is_saved=.true.
 case(6);bad%symbols(4)%kind_expr=1
 case(7);bad%symbols(4)%initializer_expr=1
 case(8);bad%symbols(4)%rank=1
 case(9);bad%code(1)%line=bad%code(1)%line-1
 case(10);bad%code(original%nc)%a=bad%code(1)%a
 case(11);bad%expressions(1)%column=bad%expressions(1)%column+1
 case(12);bad%expressions(original%ne)%left=0
 case(13);changed%code(1)%column=changed%code(1)%column+1
 case(14);bad%symbols(4)%name='n'
 case(15);bad%name='elsewhere'
 case(16);bad%symbols(4)%constant_value=value_t(tag=ty_integer,i=1_int64)
 case(17);bad%symbols(4)%name='N'
 case(18);bad%symbols(4)%name='Fresh'
 case(19);bad%symbols(4)%name='1bad'
 case(20);bad%symbols(4)%name='_bad'
 case(21);bad%symbols(4)%name='new name'
 case(22);bad%symbols(4)%name='do'
 case(23);bad%symbols(4)%name='abs'
 case(24);bad%symbols(4)%name='x'//achar(0)
 end select
 trial=copy;d=diagnostic_t();call grow_scalar_session(trial,changed,bad,5,d)
 call check(d%code/=0,'forgery rejected');call unchanged(trial)
end do
do k=1,4
 trial=copy;d=diagnostic_t()
 select case(k)
 case(1);call grow_scalar_session(trial,original,candidate,0,d)
 case(2);call grow_scalar_session(trial,original,candidate,10004,d)
 case(3);call grow_scalar_session(trial,original,candidate,4,d)
 case(4);call grow_scalar_session(trial,original,candidate,6,d)
 end select
 call check(d%code/=0,'map rejected');call unchanged(trial)
end do
trial=copy;d=diagnostic_t();call grow_scalar_session(trial,original,candidate,5,d)
call check(d%code==0,'success');call unchanged_values(trial)
call check(scalar_session_frontier(trial)==frontier,'frontier unchanged after success')
call inspect_scalar_session(trial,4,v,defined,d);call check(.not.defined,'new symbol undefined after success')
call execute_scalar_session(trial,candidate,d);call check(d%code==0,'successful suffix')
call execute_scalar_session(trial,candidate,d);call inspect_scalar_session(trial,1,v,defined,d)
call check(v%i==9,'repeated execution no suffix replay');call unchanged(copy)
print *, 'independent growth checks:',checks
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
subroutine unchanged(x)
 type(scalar_session_t),intent(in)::x
 call check(.not.scalar_session_tainted(x),'not tainted')
 call check(scalar_session_frontier(x)==frontier,'frontier unchanged')
 call unchanged_values(x)
end subroutine
subroutine unchanged_values(x)
 type(scalar_session_t),intent(in)::x
 type(diagnostic_t)::e
 call inspect_scalar_session(x,1,v,defined,e);call check(e%code==0.and.defined.and.v%i==7,'scalar preserved')
 call inspect_scalar_session(x,2,v,defined,e)
 call check(e%code==0.and.defined,'character defined')
 call check(allocated(v%s),'character owned');call check(v%s=='AbC','character preserved')
 call inspect_session_array(x,3,av,flags,lo,e)
 call check(e%code==0.and.lo==1.and.size(av)==2,'array metadata preserved')
 call check(flags(1).and..not.flags(2).and.av(1)%i==3,'partial array preserved')
end subroutine
end program
