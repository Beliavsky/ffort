program p
implicit none
integer::a(2,1,2),b(2,1,2)
real(8)::x(2,1,2)
a(:,1,1)=[1,2];a(:,1,2)=[3,4]
b(:,1,1)=[3,2];b(:,1,2)=[1,-1]
x(:,1,1)=[1d0,2d0];x(:,1,2)=[3d0,4d0]
print *,dim(a,b),sign(a,-b),log_gamma(x)
end program
