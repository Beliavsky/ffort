program p
implicit none
real::x
real(8)::y(2,2)
print *,kind(isnan(x)),kind(isnan(y))
end program
