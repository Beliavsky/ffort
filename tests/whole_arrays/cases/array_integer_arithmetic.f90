program probe
implicit none
integer :: a(3), b(-1:1), c(3)
a(1)=-7
a(2)=8
a(3)=-9
b(-1)=2
b(0)=-3
b(1)=-4
c=a/b
print *, a+b,a-b,a*b,c
end program probe
