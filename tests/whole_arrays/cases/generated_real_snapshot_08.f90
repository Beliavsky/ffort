program probe
implicit none
real :: a(-2:2),b(5:9)
a(-2)=-1.5
a(-1)=3.5
a(0)=1.5
a(1)=2.5
a(2)=2.75
b(5)=-2.75
b(6)=-3.75
b(7)=4.0
b(8)=-2.5
b(9)=-0.5
a=(a+b)*0.5+a(1)
b=abs(a)-1.25
a=(a+b)*0.5+a(1)
b=abs(a)-1.25
a=(a+b)*0.5+a(1)
b=abs(a)-1.25
a=(a+b)*0.5+a(-1)
b=abs(a)-1.25
a=(a+b)*0.5+a(-1)
b=abs(a)-1.25
print *,a,b,a>b
end program probe
