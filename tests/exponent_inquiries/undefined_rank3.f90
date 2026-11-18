program main
implicit none
real::x(2,3,2)
real(8)::y(2,3,2)
print *,minexponent(x=x),maxexponent(x=x),minexponent(x=y),maxexponent(x=y)
end program
