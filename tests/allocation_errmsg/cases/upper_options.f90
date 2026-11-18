program p
implicit none
integer,allocatable :: a(:)
integer :: stat
character(80) :: msg
msg='retained'
ALLOCATE(a(2),STAT=stat,ERRMSG=msg)
if(stat/=0.or.msg/="retained")error stop 1
end program
