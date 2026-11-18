program probe
implicit none
integer :: a(3), b(3), c(3)
a(1)=-3
a(2)=4
a(3)=5
b(1)=2
b(2)=-5
b(3)=8
c=min(1,a,b)
print *, c,max(a,3,b),min(a,b,0,7),max(-9,a,b,6)
end program probe
