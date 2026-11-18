program p
implicit none
character(:),allocatable :: a(:),b(:)
allocate(character(3)::a(-2:0))
a='abc'
call move_alloc(to=b,from=a)
if(allocated(a).or..not.allocated(b)) error stop 1
if(size(b)/=3) error stop 2
if(.not.all(b=='abc')) error stop 3
if(lbound(b,1)/=-2.or.ubound(b,1)/=0) error stop 4

end program
