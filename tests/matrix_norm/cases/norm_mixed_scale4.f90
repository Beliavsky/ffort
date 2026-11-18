program p
implicit none
real(4)::x(3),v
x=[huge(0.0_4)/2.0_4,tiny(0.0_4),0.0_4]
v=norm2(x)
if(v/=x(1)) error stop 1
end program
