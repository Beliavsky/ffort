program main
implicit none
real::x(-2:0,4:3,-5:-4)
if(any(lbound(x)/=[-2,1,-5])) error stop 1
end program
