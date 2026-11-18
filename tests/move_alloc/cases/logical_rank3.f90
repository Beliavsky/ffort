program p
implicit none
logical,allocatable :: a(:,:,:),b(:,:,:)
allocate(a(-2:0,4:5,0:1))
a=.true.
call move_alloc(to=b,from=a)
if(allocated(a).or..not.allocated(b)) error stop 1
if(size(b)/=12) error stop 2
if(.not.all(b.eqv..true.)) error stop 3
if(lbound(b,1)/=-2.or.ubound(b,1)/=0) error stop 4
if(lbound(b,2)/=4.or.ubound(b,2)/=5) error stop 5
if(lbound(b,3)/=0.or.ubound(b,3)/=1) error stop 6

end program
