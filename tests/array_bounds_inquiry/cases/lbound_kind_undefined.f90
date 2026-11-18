program main
implicit none
real::x(2,3)
integer::d
if(kind(lbound(x,dim=d,kind=8))/=8) error stop 1
end program
