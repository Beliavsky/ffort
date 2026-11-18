program main
implicit none
real(8)::x(2),a(0),b(0)
b=a+norm2(x)
if(size(b)/=0) error stop 1
end program
