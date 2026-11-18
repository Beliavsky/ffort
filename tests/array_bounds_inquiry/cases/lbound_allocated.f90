program main
implicit none
real,allocatable::x(:,:)
allocate(x(-2:0,5:6))
if(any(lbound(x)/=[-2,5])) error stop 1
if(any(lbound(x(:,5:6))/=[1,1])) error stop 2
end program
