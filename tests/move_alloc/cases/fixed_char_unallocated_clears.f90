program p
implicit none
character(3),allocatable :: a(:),b(:)
allocate(b(2))
b='abc'
call move_alloc(a,b)
if(allocated(a).or.allocated(b)) error stop 1
call move_alloc(a,b)
if(allocated(a).or.allocated(b)) error stop 2
end program
