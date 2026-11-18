program p
implicit none
integer,allocatable :: a(:)
character(80),allocatable :: msg
integer :: stat
allocate(a(1),stat=stat,errmsg=msg)
end program
