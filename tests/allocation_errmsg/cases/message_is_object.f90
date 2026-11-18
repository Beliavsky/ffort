program p
implicit none
integer,allocatable :: a(:)
integer :: stat
character(80),allocatable :: msg
stat=2
allocate(msg,errmsg=msg)
end program
