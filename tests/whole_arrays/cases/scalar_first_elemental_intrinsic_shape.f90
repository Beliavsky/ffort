program probe
implicit none
integer :: a(3),b(3)
a(1)=2
a(2)=3
a(3)=4
b=max(1,2,a)
print *,b,min(9,8,a),mod(20,a)
end program probe
