program probe
implicit none
integer :: a(-2:3),b(12:17)
a(-2)=-5
a(-1)=7
a(0)=-3
a(1)=-4
a(2)=7
a(3)=-1
b(12)=-1
b(13)=5
b(14)=-7
b(15)=-8
b(16)=-9
b(17)=0
b=(-3)-a
b=min(abs(a),17)
b=(-2)-a
a=a+(2)*b
a=a+a(0)
a=a+(3)*b
print *,a,b,a>=b
end program probe
