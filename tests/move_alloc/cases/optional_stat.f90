program p
implicit none
integer,allocatable :: a(:),b(:)
integer :: stat
call move_alloc(a,b,stat=stat)
end program
