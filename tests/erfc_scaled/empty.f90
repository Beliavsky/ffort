program p
implicit none
real::x(0),y(0,2),z(2,0,2)
print *,size(erfc_scaled(x)),size(erfc_scaled(y)),size(erfc_scaled(z))
end program
