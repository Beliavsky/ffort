program p
implicit none
real(4)::x(1),v
x=nearest(0.0_4,1.0_4)
v=norm2(x)
if(v/=x(1).or.v<=0.0_4) error stop 1
end program
