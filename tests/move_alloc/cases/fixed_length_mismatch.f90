program p
implicit none
character(2),allocatable :: a(:)
character(3),allocatable :: b(:)
call move_alloc(a,b)
end program
