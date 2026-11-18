program main
implicit none
real(4)::x(2),a(3),b(3)
x=[3.0_4,4.0_4]
a=2.0_4
b=a+norm2(x,dim=1_8)
if(any(b/=7.0_4)) error stop 1
end program
