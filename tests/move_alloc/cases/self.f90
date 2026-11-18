program p
implicit none
integer,allocatable :: a(:)
call move_alloc(a,a)
end program
