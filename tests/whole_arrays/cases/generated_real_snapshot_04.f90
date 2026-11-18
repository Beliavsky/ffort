program probe
implicit none
real :: a(-2:2),b(5:9)
a(-2)=4.0
a(-1)=1.75
a(0)=2.0
a(1)=-3.25
a(2)=-3.75
b(5)=-2.25
b(6)=2.25
b(7)=3.25
b(8)=-1.75
b(9)=1.0
a=(a+b)*0.5+a(2)
b=abs(a)-1.25
a=(a+b)*0.5+a(2)
b=abs(a)-1.25
a=(a+b)*0.5+a(1)
b=abs(a)-1.25
a=(a+b)*0.5+a(1)
b=abs(a)-1.25
a=(a+b)*0.5+a(-2)
b=abs(a)-1.25
print *,a,b,a>b
end program probe
