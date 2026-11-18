program p
implicit none
print *,erfc_scaled(2d0)
contains
real(8) function erfc_scaled(x)
real(8),intent(in)::x
erfc_scaled=x+1d0
end function
end program
