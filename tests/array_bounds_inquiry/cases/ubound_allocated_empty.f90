program main
implicit none
real,allocatable::x(:,:)
allocate(x(4:3,5:6))
if(any(ubound(x)/=[0,6])) error stop 1
end program
