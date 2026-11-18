program p
implicit none
integer,allocatable :: a(:)
integer(kind=4) :: stat
character(len=256) :: msg,prior
msg='unchanged';prior=msg
allocate(a(2),stat=stat,errmsg=msg)
if(stat/=0) error stop 1
if(msg/=prior) error stop 2
allocate(a(4),errmsg=msg,stat=stat)
if(stat==0) error stop 3
if(size(a)/=2) error stop 4
if(len(msg)/=256) error stop 5
if(len_trim(msg)==0) error stop 6
if(msg(80:80)/=" ") error stop 7
deallocate(a,errmsg=msg,stat=stat)
if(stat/=0.or.allocated(a)) error stop 8
deallocate(a,stat=stat,errmsg=msg)
if(stat==0) error stop 9

end program
