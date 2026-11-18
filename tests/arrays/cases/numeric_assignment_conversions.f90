program probe
implicit none
integer :: a(2)
real :: b(2)
a(1)=-3.75
a(2)=3.75
b(1)=a(1)
b(2)=5/2
print *,a(1),a(2),b(1),b(2)
end program probe
