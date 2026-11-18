program p
implicit none
real(8)::x(3)
x=[-2d0,0d0,2d0]
print *,erfc_scaled(x)
end program
