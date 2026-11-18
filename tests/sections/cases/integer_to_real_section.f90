program probe
implicit none
real :: b(-1:1)
integer :: a(1:5)
a(1)=1
a(2)=2
a(3)=3
a(4)=4
a(5)=5
b(1:-1:-1)=a(1:5:2)
print *, b
end program probe
