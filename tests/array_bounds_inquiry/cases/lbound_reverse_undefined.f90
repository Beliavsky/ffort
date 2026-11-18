program main
implicit none
real::x(-2:0,5:6)
if(any(lbound(x(0:-2:-1,:))/=[1,1])) error stop 1
end program
