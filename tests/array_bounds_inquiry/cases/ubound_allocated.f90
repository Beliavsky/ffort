program main
implicit none
real,allocatable::x(:,:)
allocate(x(-2:0,5:6))
if(any(ubound(x)/=[0,6])) error stop 1
if(any(ubound(x(:,5:6))/=[3,2])) error stop 2
end program
