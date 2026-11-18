module limits
implicit none
real(8)::x
integer,parameter::lower=minexponent(x),upper=maxexponent(x)
end module
program main
use limits
implicit none
integer::a(maxexponent(1.0)-minexponent(1.0))
print *,lower,upper,size(a)
end program
