program p
implicit none
integer,allocatable :: a(:),b(:)
allocate(a(-3:-1),b(10))
a=[3,4,5];b=99
call move_alloc(a,b)
if(allocated(a).or.size(b)/=3.or.lbound(b,1)/=-3) error stop 1
if(any(b/=[3,4,5])) error stop 2
allocate(a(2))
a=7
if(any(b/=[3,4,5])) error stop 3
end program
