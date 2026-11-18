program probe
implicit none
integer :: a(3), b(3)
a(1)=-2
a(2)=0
a(3)=3
b=-a**2
print *, b,(-a)**2,+a,2**a**2
end program probe
