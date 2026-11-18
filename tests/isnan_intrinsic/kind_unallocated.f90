program p
implicit none
real(8),allocatable::x(:)
print *,kind(isnan(x))
end program
