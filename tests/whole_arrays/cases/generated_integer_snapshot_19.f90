program probe
implicit none
integer :: a(-4:-4),b(13:13)
a(-4)=0
b(13)=-4
b=(-4)-a
a=a+a(-4)
a=a+a(-4)
a=a+(-1)*b
b=min(abs(a),17)
a=a+a(-4)
print *,a,b,a>=b
end program probe
