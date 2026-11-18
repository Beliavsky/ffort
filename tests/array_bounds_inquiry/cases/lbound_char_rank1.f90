program main
implicit none
character(3)::x(-2:0)
if(any(lbound(x)/=[-2])) error stop 1
if(size(lbound(x))/=1.or.kind(lbound(x))/=4) error stop 2
end program
