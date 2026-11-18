program probe
implicit none
integer :: a(2)
real :: b(2)
b(1)=1.0
b(2)=3.0e9
print *,99
a=int(b)
end program probe
