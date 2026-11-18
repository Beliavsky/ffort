program p
implicit none
real(8)::a(3)=[1.23456789012345_8,2.0_8,3.123456789012345_8]
real(4)::b(4)=[1.0,2.0,3.0,4.0]
a=real(a(3:1:-1),4)
print *,a
b=real(b(4:1:-1),8)
print *,b
b(2:4)=real(b(1:3),8)
print *,b
end program p
