program probe
implicit none
integer :: a(2),b(0:3),c(-2:-1)
a(2)=2
b(0)=3
b(3)=4
c(-2)=5
c(-1)=6
print *,a(2),b(0),b(3),c(-2),c(-1)
end program probe
