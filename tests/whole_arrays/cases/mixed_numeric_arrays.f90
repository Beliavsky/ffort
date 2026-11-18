program probe
implicit none
integer :: a(3), c(3)
real :: b(3), d(3)
a(1)=1
a(2)=-3
a(3)=7
b(1)=0.5
b(2)=-1.5
b(3)=2.25
d=a+b*2
c=d
print *, d,c,b/a
end program probe
