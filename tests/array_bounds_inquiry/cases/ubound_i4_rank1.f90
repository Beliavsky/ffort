program main
implicit none
integer::x(-2:0)
if(any(ubound(x)/=[0])) error stop 1
if(size(ubound(x))/=1.or.kind(ubound(x))/=4) error stop 2
end program
