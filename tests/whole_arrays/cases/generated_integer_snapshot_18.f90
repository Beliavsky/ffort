program probe
implicit none
integer :: a(-4:0),b(8:12)
a(-4)=0
a(-3)=3
a(-2)=-3
a(-1)=-5
a(0)=-6
b(8)=7
b(9)=-2
b(10)=-8
b(11)=-5
b(12)=4
b=(-3)-a
b=min(abs(a),17)
b=(4)-a
b=(1)-a
a=a+(-2)*b
b=min(abs(a),17)
print *,a,b,a>=b
end program probe
