program main
implicit none
real(8)::x(2),a(3)
integer::d
if(kind(a+norm2(x,d))/=8) error stop 1
end program
