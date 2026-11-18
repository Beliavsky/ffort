program p
implicit none
integer,allocatable :: a(:)
integer :: stat
character(80) :: msg
msg='retained'
allocate(a(2),sTaT=stat,ErRmSg=msg)
if(stat/=0.or.msg/="retained")error stop 1
end program
