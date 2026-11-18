program probe
implicit none
real :: a(-2:2),b(5:9)
a(-2)=2.0
a(-1)=1.75
a(0)=-0.75
a(1)=-1.25
a(2)=3.0
b(5)=0.25
b(6)=0.75
b(7)=3.5
b(8)=-2.75
b(9)=-3.25
a=(a+b)*0.5+a(0)
b=abs(a)-1.25
a=(a+b)*0.5+a(0)
b=abs(a)-1.25
a=(a+b)*0.5+a(0)
b=abs(a)-1.25
a=(a+b)*0.5+a(1)
b=abs(a)-1.25
a=(a+b)*0.5+a(0)
b=abs(a)-1.25
print *,a,b,a>b
end program probe
