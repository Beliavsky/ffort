program main
implicit none
real::x(-2:0,5:6,4:3)
if(any(ubound(x)/=[0,6,0])) error stop 1
end program
