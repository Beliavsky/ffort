program p
implicit none
integer,allocatable :: a(:),b(:,:)
call move_alloc(a,b)
end program
