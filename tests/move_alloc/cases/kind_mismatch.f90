program p
implicit none
integer,allocatable :: a(:)
integer(8),allocatable :: b(:)
call move_alloc(a,b)
end program
