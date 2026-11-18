program main
implicit none
integer::x(-2:0,5:6)
if(any(ubound(x)/=[0,6])) error stop 1
if(size(ubound(x))/=2.or.kind(ubound(x))/=4) error stop 2
end program
