program main
implicit none
real::x(-2:0,5:6,4:3)
if(any(lbound(x)/=[-2,5,1])) error stop 1
end program
