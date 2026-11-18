program p
implicit none
integer,allocatable :: a(:)
integer :: stat
integer :: msg
allocate(a(1),stat=stat,errmsg=msg)
end program
