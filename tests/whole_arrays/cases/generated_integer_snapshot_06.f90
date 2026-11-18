program probe
implicit none
integer :: a(-4:2),b(12:18)
a(-4)=5
a(-3)=0
a(-2)=6
a(-1)=0
a(0)=8
a(1)=9
a(2)=-7
b(12)=4
b(13)=-3
b(14)=2
b(15)=0
b(16)=2
b(17)=-8
b(18)=0
a=a+(2)*b
b=(0)-a
a=a+a(2)
a=a+a(-3)
b=min(abs(a),17)
a=a+a(0)
print *,a,b,a>=b
end program probe
