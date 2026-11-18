program p
implicit none
integer,allocatable :: a(:,:,:),b(:,:,:)
allocate(a(-2:1,5:4,2:3))
call move_alloc(a,b)
if(allocated(a).or..not.allocated(b).or.size(b)/=0) error stop 1
if(any(lbound(b)/=[-2,1,2])) error stop 2
end program
