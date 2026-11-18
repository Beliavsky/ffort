program p
implicit none
integer,allocatable :: a(:),b(:)
call move_alloc(from=a,from=b)
end program
