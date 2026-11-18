program p
implicit none
integer,allocatable :: a(:)
call move_alloc(from=a)
end program
