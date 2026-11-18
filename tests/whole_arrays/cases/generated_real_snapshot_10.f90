program probe
implicit none
real :: a(-2:2),b(5:9)
a(-2)=2.0
a(-1)=0.75
a(0)=1.5
a(1)=3.75
a(2)=-0.5
b(5)=3.0
b(6)=-0.5
b(7)=-2.25
b(8)=-1.75
b(9)=-0.75
a=(a+b)*0.5+a(2)
b=abs(a)-1.25
a=(a+b)*0.5+a(-1)
b=abs(a)-1.25
a=(a+b)*0.5+a(0)
b=abs(a)-1.25
a=(a+b)*0.5+a(2)
b=abs(a)-1.25
a=(a+b)*0.5+a(2)
b=abs(a)-1.25
print *,a,b,a>b
end program probe
