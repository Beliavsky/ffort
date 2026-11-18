program main
implicit none
real::x(-2:0,4:3,-5:-4)
if(any(ubound(x)/=[0,0,-4])) error stop 1
end program
