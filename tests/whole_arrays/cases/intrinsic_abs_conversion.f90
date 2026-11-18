program probe
implicit none
integer :: a(3), b(3)
real :: r(3)
a(1)=-3
a(2)=0
a(3)=5
r=real(a)/2.0
b=int(r)
print *, abs(a),abs(r),b,real(b)
end program probe
