program probe
implicit none
integer :: a(1:5),b(10:14)
a(1)=3
a(2)=-5
a(3)=1
a(4)=2
a(5)=2
b(10)=7
b(11)=-3
b(12)=6
b(13)=6
b(14)=-5
b=(3)-a
a=a+(3)*b
b=min(abs(a),17)
a=a+a(4)
b=(0)-a
a=a+a(5)
print *,a,b,a>=b
end program probe
