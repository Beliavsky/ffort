program main
implicit none
integer::x(-2:0,5:6)
if(any(lbound(x)/=[-2,5])) error stop 1
if(size(lbound(x))/=2.or.kind(lbound(x))/=4) error stop 2
end program
