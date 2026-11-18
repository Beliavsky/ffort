program probe
implicit none
real :: a(3)
integer :: n(3)
a(1)=4.0
a(2)=9.0
a(3)=16.0
n(1)=1
n(2)=2
n(3)=3
print *, a**0.5,2.0**n,a**n
end program probe
