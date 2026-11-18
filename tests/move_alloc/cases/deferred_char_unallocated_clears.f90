program p
implicit none
character(:),allocatable :: a(:),b(:)
allocate(character(3)::b(2))
b='abc'
call move_alloc(a,b)
if(allocated(a).or.allocated(b)) error stop 1
call move_alloc(a,b)
if(allocated(a).or.allocated(b)) error stop 2
end program
