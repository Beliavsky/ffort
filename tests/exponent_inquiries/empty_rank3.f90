program main
implicit none
real::x(2,0,3)
real(8)::y(2,0,3)
print *,minexponent(x),maxexponent(x),minexponent(y),maxexponent(y)
end program
