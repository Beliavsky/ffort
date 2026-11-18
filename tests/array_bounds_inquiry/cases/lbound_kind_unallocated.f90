program main
implicit none
character(:),allocatable::x(:,:)
if(kind(lbound(x,kind=8))/=8) error stop 1
end program
