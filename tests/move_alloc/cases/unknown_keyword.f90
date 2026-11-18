program p
implicit none
integer,allocatable :: a(:),b(:)
call move_alloc(source=a,to=b)
end program
