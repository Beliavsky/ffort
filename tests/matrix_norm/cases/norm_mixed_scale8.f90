program p
implicit none
real(8)::x(3),v
x=[huge(0.0_8)/2.0_8,tiny(0.0_8),0.0_8]
v=norm2(x)
if(v/=x(1)) error stop 1
end program
