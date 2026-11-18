program p
implicit none
real(8)::x(0,3),y(3),undefined
y=norm2(x*undefined,1)
if(any(y/=0d0)) error stop 1
end program
