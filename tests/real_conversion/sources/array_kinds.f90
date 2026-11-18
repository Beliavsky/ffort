program p
implicit none
real(4)::a(3)=[1.25,-2.5,4.0]
real(8)::b(3),c(3)
b=real(a,8)
c=[1.23456789012345_8,2.0_8,3.0_8]
print *,real(a,4),real(a,8),real(b),real(b,8)
print *,real(real(c,4),8)
print *,real(c(1),4)==1.2345678806304931640625_8
end program p
