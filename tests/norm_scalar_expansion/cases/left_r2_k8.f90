program main
implicit none
real(8)::x(2),a(2,3),b(2,3)
x=[3.0_8,4.0_8]
a=2.0_8
b=norm2(x)+a
if(any(b/=7.0_8)) error stop 1
end program
