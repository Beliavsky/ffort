program probe
implicit none
real :: a(-2:2),b(5:9)
a(-2)=-1.25
a(-1)=-0.5
a(0)=3.0
a(1)=-4.0
a(2)=-2.5
b(5)=3.0
b(6)=0.0
b(7)=-1.5
b(8)=3.0
b(9)=2.5
a=(a+b)*0.5+a(1)
b=abs(a)-1.25
a=(a+b)*0.5+a(-2)
b=abs(a)-1.25
a=(a+b)*0.5+a(-2)
b=abs(a)-1.25
a=(a+b)*0.5+a(2)
b=abs(a)-1.25
a=(a+b)*0.5+a(2)
b=abs(a)-1.25
print *,a,b,a>b
end program probe
