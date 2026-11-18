program p
implicit none
real(4),allocatable::x(:,:,:)
if(kind(norm2(x))/=4.or.kind(norm2(x,2))/=4) error stop 1
end program
