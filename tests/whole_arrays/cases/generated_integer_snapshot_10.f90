program probe
implicit none
integer :: a(-1:1),b(9:11)
a(-1)=-4
a(0)=3
a(1)=-7
b(9)=-6
b(10)=6
b(11)=5
a=a+(-3)*b
b=min(abs(a),17)
b=(1)-a
a=a+(0)*b
b=(2)-a
b=(3)-a
print *,a,b,a>=b
end program probe
