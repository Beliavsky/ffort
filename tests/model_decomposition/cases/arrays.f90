program p
implicit none
real(8)::x(2,1,2)
integer::i(2,1,2)
x(:,1,1)=[1d0,-2d0];x(:,1,2)=[3d0,-4d0];i=3
print *,fraction(x),exponent(x),set_exponent(x,i)
end program
