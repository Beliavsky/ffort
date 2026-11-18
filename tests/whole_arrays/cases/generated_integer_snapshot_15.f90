program probe
implicit none
integer :: a(2:4),b(5:7)
a(2)=9
a(3)=4
a(4)=-5
b(5)=-6
b(6)=-4
b(7)=-8
a=a+(2)*b
b=min(abs(a),17)
b=min(abs(a),17)
a=a+a(2)
b=min(abs(a),17)
b=min(abs(a),17)
print *,a,b,a>=b
end program probe
