program p
implicit none
integer,allocatable :: a(:)
integer :: stat
character(*),parameter :: msg='fixed'
allocate(a(1),stat=stat,errmsg=msg)
end program
