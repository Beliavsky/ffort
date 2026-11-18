program arrays
implicit none
real :: a(4),z(0),m(2,2),n(0,2)
real(8) :: b(-2:1),r(2,2)
a=[-1.0,-0.125,0.0,1.0]
b=[-1.0d0,-0.125d0,0.0d0,1.0d0]
m(:,1)=a(1:2)
m(:,2)=a(3:4)
r(:,1)=b(-2:-1)
r(:,2)=b(0:1)
print *, sinh(a),cosh(x=b),tanh(a)
print *, sinh(b(1:-2:-1)),cosh(a(4:1:-1)),tanh(b(-2:1:2))
print *, sinh(m),cosh(x=r),tanh(r)
print *, sum(sinh(z)),sum(cosh(z)),sum(tanh(z))
print *, sum(sinh(n)),sum(cosh(n)),sum(tanh(n)),size(cosh(n),dim=2)
print *, sum(cosh(m),dim=1),sum(tanh(r),dim=2)
end program
