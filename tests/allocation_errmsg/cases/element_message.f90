program p
implicit none
integer,allocatable :: a(:)
integer :: stat
character(80) :: msg(2)
allocate(a(1),stat=stat,errmsg=msg(1))
end program
