program p
implicit none
integer,allocatable :: a(:)
integer :: stat
character(80) :: msg
stat=2
allocate(a(1),errmsg=msg,errmsg=msg)
end program
