program probe
implicit none
real :: a(-2:2),b(5:9)
a(-2)=3.25
a(-1)=3.0
a(0)=0.5
a(1)=0.75
a(2)=3.75
b(5)=-4.0
b(6)=3.25
b(7)=-0.5
b(8)=0.75
b(9)=4.0
a=(a+b)*0.5+a(1)
b=abs(a)-1.25
a=(a+b)*0.5+a(1)
b=abs(a)-1.25
a=(a+b)*0.5+a(2)
b=abs(a)-1.25
a=(a+b)*0.5+a(0)
b=abs(a)-1.25
a=(a+b)*0.5+a(2)
b=abs(a)-1.25
print *,a,b,a>b
end program probe
