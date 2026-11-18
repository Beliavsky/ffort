program p
implicit none
integer,allocatable :: a(:)
integer :: stat
character(:),allocatable :: msg
allocate(a(1),stat=stat,errmsg=msg)
end program
