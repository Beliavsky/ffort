program probe
implicit none
integer :: a(-2:0),b(6:8)
a(-2)=3
a(-1)=-9
a(0)=-9
b(6)=9
b(7)=-1
b(8)=-3
b=(-4)-a
b=(0)-a
b=min(abs(a),17)
a=a+(3)*b
a=a+a(0)
a=a+(-1)*b
print *,a,b,a>=b
end program probe
