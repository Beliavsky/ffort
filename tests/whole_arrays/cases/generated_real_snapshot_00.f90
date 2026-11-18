program probe
implicit none
real :: a(-2:2),b(5:9)
a(-2)=1.5
a(-1)=-0.25
a(0)=-1.5
a(1)=1.5
a(2)=3.75
b(5)=2.0
b(6)=2.5
b(7)=-1.75
b(8)=-1.5
b(9)=1.75
a=(a+b)*0.5+a(0)
b=abs(a)-1.25
a=(a+b)*0.5+a(-2)
b=abs(a)-1.25
a=(a+b)*0.5+a(0)
b=abs(a)-1.25
a=(a+b)*0.5+a(2)
b=abs(a)-1.25
a=(a+b)*0.5+a(1)
b=abs(a)-1.25
print *,a,b,a>b
end program probe
