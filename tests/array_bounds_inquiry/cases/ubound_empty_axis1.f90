program main
implicit none
real::x(4:3,5:6,-5:-4)
if(any(ubound(x)/=[0,6,-4])) error stop 1
end program
