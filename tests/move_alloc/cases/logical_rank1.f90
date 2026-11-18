program p
implicit none
logical,allocatable :: a(:),b(:)
allocate(a(-2:0))
a=.true.
call move_alloc(to=b,from=a)
if(allocated(a).or..not.allocated(b)) error stop 1
if(size(b)/=3) error stop 2
if(.not.all(b.eqv..true.)) error stop 3
if(lbound(b,1)/=-2.or.ubound(b,1)/=0) error stop 4

end program
