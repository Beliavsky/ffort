program main
implicit none
real,allocatable::x(:,:)
allocate(x(4:3,5:6))
if(any(lbound(x)/=[1,5])) error stop 1
end program
