program main
implicit none
real(4)::x(2),a(3)
integer::d
if(kind(a+norm2(x,d))/=4) error stop 1
end program
