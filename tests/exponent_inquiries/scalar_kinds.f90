program main
implicit none
real::x
real(8)::y
print *,minexponent(x),maxexponent(x),minexponent(y),maxexponent(y)
print *,kind(minexponent(y)),kind(maxexponent(x))
end program
