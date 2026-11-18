program main
implicit none
real::x(2,3)
integer::d
if(kind(ubound(x,dim=d,kind=8))/=8) error stop 1
end program
