program p
implicit none
integer,allocatable :: a(:)
integer(kind=8) :: stat
character(len=0) :: msg,prior
msg='unchanged';prior=msg
allocate(a(2),stat=stat,errmsg=msg)
if(stat/=0) error stop 1
if(msg/=prior) error stop 2
allocate(a(4),errmsg=msg,stat=stat)
if(stat==0) error stop 3
if(size(a)/=2) error stop 4
if(len(msg)/=0) error stop 5
deallocate(a,errmsg=msg,stat=stat)
if(stat/=0.or.allocated(a)) error stop 8
deallocate(a,stat=stat,errmsg=msg)
if(stat==0) error stop 9

end program
