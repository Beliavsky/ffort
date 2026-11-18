program main
implicit none
real::x(-2:0,5:6)
if(any(lbound(transpose(x))/=[1,1])) error stop 1
end program
