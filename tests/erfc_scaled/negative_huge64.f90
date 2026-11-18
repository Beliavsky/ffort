program p
implicit none
real(8)::x
x=-huge(0d0)
print *,erfc_scaled(x)
end program
