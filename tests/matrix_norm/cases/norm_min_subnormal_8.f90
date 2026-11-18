program p
implicit none
real(8)::x(1),v
x=nearest(0.0_8,1.0_8)
v=norm2(x)
if(v/=x(1).or.v<=0.0_8) error stop 1
end program
