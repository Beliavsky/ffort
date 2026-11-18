program main
implicit none
real(8)::x(2),a(4)
x=[3.0_8,4.0_8]
a=norm2(x)
if(any(a/=5.0_8)) error stop 1
end program
