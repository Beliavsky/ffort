program probe
implicit none
integer :: a(0:5),b(12:17)
a(0)=0
a(1)=0
a(2)=-2
a(3)=9
a(4)=1
a(5)=3
b(12)=4
b(13)=-2
b(14)=-6
b(15)=-6
b(16)=7
b(17)=-4
a=a+(-1)*b
b=min(abs(a),17)
b=min(abs(a),17)
a=a+a(0)
a=a+(3)*b
a=a+(2)*b
print *,a,b,a>=b
end program probe
