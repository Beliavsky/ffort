program probe
implicit none
integer :: a(-1:2),b(8:11)
a(-1)=-2
a(0)=5
a(1)=-5
a(2)=7
b(8)=9
b(9)=-3
b(10)=2
b(11)=-3
b=min(abs(a),17)
b=min(abs(a),17)
b=(-3)-a
a=a+a(1)
a=a+a(2)
b=min(abs(a),17)
print *,a,b,a>=b
end program probe
