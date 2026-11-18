program p
implicit none
integer,allocatable :: a(:)
integer :: stat
character(80) :: msg
stat=2
allocate(a(stat),stat=stat,errmsg=msg)
end program
