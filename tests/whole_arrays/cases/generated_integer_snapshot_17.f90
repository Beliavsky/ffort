program probe
implicit none
integer :: a(-3:0),b(12:15)
a(-3)=-6
a(-2)=2
a(-1)=-6
a(0)=-9
b(12)=-9
b(13)=-4
b(14)=-7
b(15)=-1
b=min(abs(a),17)
a=a+a(-2)
a=a+a(0)
b=(0)-a
b=(-3)-a
b=min(abs(a),17)
print *,a,b,a>=b
end program probe
