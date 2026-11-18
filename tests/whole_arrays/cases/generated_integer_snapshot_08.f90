program probe
implicit none
integer :: a(0:6),b(11:17)
a(0)=-1
a(1)=0
a(2)=-1
a(3)=3
a(4)=9
a(5)=3
a(6)=2
b(11)=-4
b(12)=0
b(13)=6
b(14)=7
b(15)=7
b(16)=5
b(17)=3
a=a+a(3)
b=min(abs(a),17)
b=min(abs(a),17)
a=a+(-2)*b
a=a+a(6)
a=a+a(3)
print *,a,b,a>=b
end program probe
