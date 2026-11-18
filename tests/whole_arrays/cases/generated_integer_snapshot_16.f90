program probe
implicit none
integer :: a(0:0),b(9:9)
a(0)=8
b(9)=3
a=a+a(0)
b=(-1)-a
b=min(abs(a),17)
a=a+(3)*b
b=min(abs(a),17)
a=a+a(0)
print *,a,b,a>=b
end program probe
