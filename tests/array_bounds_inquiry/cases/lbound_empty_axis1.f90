program main
implicit none
real::x(4:3,5:6,-5:-4)
if(any(lbound(x)/=[1,5,-5])) error stop 1
end program
