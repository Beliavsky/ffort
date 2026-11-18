program p
implicit none
real(8)::x(2),v
x=[3.0_8,4.0_8]
v=norm2(x)
if(v/=5.0_8.or.kind(v)/=8) error stop 1
if(norm2(x,dim=1)/=5.0_8) error stop 2
end program
