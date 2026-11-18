program probe
implicit none
integer :: a(-3:2),b(14:19)
a(-3)=-7
a(-2)=-2
a(-1)=-4
a(0)=-6
a(1)=2
a(2)=7
b(14)=-4
b(15)=1
b(16)=-5
b(17)=5
b(18)=0
b(19)=-4
a=a+a(0)
b=(-2)-a
a=a+a(-2)
a=a+(-2)*b
b=min(abs(a),17)
b=min(abs(a),17)
print *,a,b,a>=b
end program probe
