program probe
implicit none
integer :: a(3)
real :: r(3)
a(1)=-3
a(2)=4
a(3)=-7
r=max(abs(real(a)/2.0),1.0)
print *, r,int(r),min(abs(a),5)
end program probe
