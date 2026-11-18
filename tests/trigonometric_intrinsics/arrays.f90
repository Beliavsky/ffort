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
print *, sin(a),cos(x=b),tan(a)
print *, sin(b(1:-2:-1)),cos(a(4:1:-1)),tan(b(-2:1:2))
print *, sin(m),cos(x=r),tan(r)
print *, sum(sin(z)),sum(cos(z)),sum(tan(z))
print *, sum(sin(n)),sum(cos(n)),sum(tan(n)),size(cos(n),dim=2)
print *, sum(cos(m),dim=1),sum(tan(r),dim=2)
end program
