program p
implicit none
real(8),allocatable :: a(:),b(:)
allocate(b(2))
b=3.0_8
call move_alloc(a,b)
if(allocated(a).or.allocated(b)) error stop 1
call move_alloc(a,b)
if(allocated(a).or.allocated(b)) error stop 2
end program
