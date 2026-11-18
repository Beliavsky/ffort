program probe
implicit none
integer :: a(-2:-2),b(13:13)
a(-2)=9
b(13)=6
a=a+a(-2)
a=a+(0)*b
a=a+a(-2)
a=a+a(-2)
b=min(abs(a),17)
b=min(abs(a),17)
print *,a,b,a>=b
end program probe
