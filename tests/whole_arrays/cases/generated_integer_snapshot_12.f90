program probe
implicit none
integer :: a(-1:5),b(6:12)
a(-1)=-8
a(0)=-2
a(1)=0
a(2)=-7
a(3)=5
a(4)=-6
a(5)=5
b(6)=-6
b(7)=3
b(8)=-7
b(9)=5
b(10)=5
b(11)=2
b(12)=9
b=(-1)-a
b=min(abs(a),17)
a=a+a(3)
b=(-2)-a
a=a+a(3)
b=(3)-a
print *,a,b,a>=b
end program probe
