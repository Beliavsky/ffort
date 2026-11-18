program probe
implicit none
real :: a(-2:2),b(5:9)
a(-2)=-2.0
a(-1)=2.25
a(0)=-0.75
a(1)=2.25
a(2)=0.25
b(5)=3.75
b(6)=1.0
b(7)=-2.25
b(8)=1.75
b(9)=1.25
a=(a+b)*0.5+a(2)
b=abs(a)-1.25
a=(a+b)*0.5+a(-2)
b=abs(a)-1.25
a=(a+b)*0.5+a(0)
b=abs(a)-1.25
a=(a+b)*0.5+a(2)
b=abs(a)-1.25
a=(a+b)*0.5+a(-2)
b=abs(a)-1.25
print *,a,b,a>b
end program probe
