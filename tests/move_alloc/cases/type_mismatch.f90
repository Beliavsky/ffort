program p
implicit none
integer,allocatable :: a(:)
real,allocatable :: b(:)
call move_alloc(a,b)
end program
