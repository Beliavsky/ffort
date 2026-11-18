program probe
implicit none
integer :: a(2:6),b(12:16)
a(2)=-3
a(3)=-9
a(4)=3
a(5)=1
a(6)=-3
b(12)=4
b(13)=4
b(14)=-5
b(15)=7
b(16)=-1
b=(1)-a
a=a+a(2)
a=a+(0)*b
a=a+a(5)
b=min(abs(a),17)
a=a+(-3)*b
print *,a,b,a>=b
end program probe
