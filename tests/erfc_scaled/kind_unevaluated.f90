program p
implicit none
real::x
real(8),allocatable::y(:)
print *,kind(erfc_scaled(x)),kind(erfc_scaled(y))
end program
