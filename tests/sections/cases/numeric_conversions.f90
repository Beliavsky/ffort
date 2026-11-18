program probe
implicit none
integer :: b(3)
real :: a(1:4)
a(1)=1.5
a(2)=-2.5
a(3)=3.5
a(4)=4.5
b=a(4:2:-1)
a(1:3)=b
print *, a,b
end program probe
