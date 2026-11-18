program probe
implicit none
integer :: a(-5:-2),b(14:17)
a(-5)=-8
a(-4)=9
a(-3)=-7
a(-2)=5
b(14)=-2
b(15)=5
b(16)=-7
b(17)=1
a=a+a(-3)
a=a+(2)*b
a=a+a(-5)
b=min(abs(a),17)
a=a+(-2)*b
b=(-3)-a
print *,a,b,a>=b
end program probe
