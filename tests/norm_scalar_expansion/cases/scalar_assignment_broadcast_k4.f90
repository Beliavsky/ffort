program main
implicit none
real(4)::x(2),a(4)
x=[3.0_4,4.0_4]
a=norm2(x)
if(any(a/=5.0_4)) error stop 1
end program
