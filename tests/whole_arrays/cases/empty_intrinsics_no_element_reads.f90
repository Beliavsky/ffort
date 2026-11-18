program probe
implicit none
integer :: a(0), b(0), c
real :: r(0)
a=min(b,c)
r=real(a)/real(c)
print *, a,r,9
end program probe
