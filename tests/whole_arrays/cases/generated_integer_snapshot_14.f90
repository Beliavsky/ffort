program probe
implicit none
integer :: a(-1:5),b(10:16)
a(-1)=0
a(0)=-6
a(1)=-3
a(2)=7
a(3)=1
a(4)=4
a(5)=-8
b(10)=-4
b(11)=-9
b(12)=-5
b(13)=3
b(14)=1
b(15)=8
b(16)=4
b=(2)-a
b=min(abs(a),17)
a=a+a(-1)
b=min(abs(a),17)
a=a+a(5)
a=a+(-2)*b
print *,a,b,a>=b
end program probe
