program p
implicit none
logical,allocatable :: a(:),b(:)
allocate(b(2))
b=.true.
call move_alloc(a,b)
if(allocated(a).or.allocated(b)) error stop 1
call move_alloc(a,b)
if(allocated(a).or.allocated(b)) error stop 2
end program
