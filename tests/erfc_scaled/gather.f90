program p
implicit none
real(8)::x(3,2)
x=1d0
print *,erfc_scaled(x([3,1],:))
end program
