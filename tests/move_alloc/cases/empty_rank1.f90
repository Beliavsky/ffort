program p
implicit none
integer,allocatable :: a(:),b(:)
allocate(a(-2:-3))
call move_alloc(a,b)
if(allocated(a).or..not.allocated(b).or.size(b)/=0) error stop 1
if(any(lbound(b)/=1)) error stop 2
end program
