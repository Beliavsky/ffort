program p
implicit none
integer,allocatable :: a(:)
integer :: stat
character(80) :: msg
allocate(a(1),stat=stat,errmsg=(msg))
end program
