program main
implicit none
real(4)::x(2),a(2,3),b(2,3)
x=[3.0_4,4.0_4]
a=2.0_4
b=norm2(x)+a
if(any(b/=7.0_4)) error stop 1
end program
