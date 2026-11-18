program p
implicit none
real(8)::x(2,1,2),y(2,1,2)
x=1d0
y=erfc_scaled(x)
print *,shape(y),y
end program
