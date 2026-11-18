program probe
implicit none
integer :: a(2:6),b(7:11)
a(2)=-4
a(3)=-1
a(4)=-9
a(5)=-2
a(6)=-6
b(7)=-7
b(8)=-7
b(9)=-1
b(10)=-7
b(11)=7
b=min(abs(a),17)
a=a+a(2)
a=a+a(5)
b=(-3)-a
b=min(abs(a),17)
b=min(abs(a),17)
print *,a,b,a>=b
end program probe
