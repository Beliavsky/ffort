program p
implicit none
real(8)::x(0),y(0,2),z(2,0,2)
print *,size(aint(x)),size(anint(y,4)),size(asinh(z)),size(acosh(x))
print *,kind(aint(x,4)),kind(anint(x,8)),kind(asinh(z)),kind(acosh(x))
end program
