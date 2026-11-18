program p
implicit none
double precision, save :: a(2)=[1.25d0,-2.5d0]
real, save :: b(2)=[2.0,4.0]
real(kind=8) :: c(2)
c=dprod(real(a,kind=4),b)
print '(2(f6.2,1x))',c
print '(l1)',abs(acos(-1.0_8)-3.141592653589793_8)<1.0e-15_8
end program
