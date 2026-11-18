program main
implicit none
real::x(-2:0,5:6)
if(any(ubound(transpose(x))/=[2,3])) error stop 1
end program
