program main
implicit none
real(8)::x(2),a(2,0,3),b(2,0,3)
b=a+norm2(x)
if(size(b)/=0) error stop 1
end program
