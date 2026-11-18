program p
implicit none
integer,allocatable :: a(:)
character(80),allocatable :: msg
integer :: stat
allocate(msg)
msg='retained'
allocate(a(1),stat=stat,errmsg=msg)
if(stat/=0.or.msg/='retained') error stop 1
allocate(a(1),stat=stat,errmsg=msg)
if(stat==0.or.len_trim(msg)==0.or.len(msg)/=80) error stop 2
end program
