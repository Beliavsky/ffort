program p
implicit none
real(8)::x(1),v
x=huge(0.0_8)
v=norm2(x)
if(v/=x(1)) error stop 1
end program
