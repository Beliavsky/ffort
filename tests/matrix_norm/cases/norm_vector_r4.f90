program p
implicit none
real(4)::x(2),v
x=[3.0_4,4.0_4]
v=norm2(x)
if(v/=5.0_4.or.kind(v)/=4) error stop 1
if(norm2(x,dim=1)/=5.0_4) error stop 2
end program
