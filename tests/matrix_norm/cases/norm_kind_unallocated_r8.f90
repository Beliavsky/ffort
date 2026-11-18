program p
implicit none
real(8),allocatable::x(:,:,:)
if(kind(norm2(x))/=8.or.kind(norm2(x,2))/=8) error stop 1
end program
