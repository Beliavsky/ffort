program main
implicit none
real::x(-2:0,5:6)
if(any(ubound((x))/=[3,2])) error stop 1
end program
