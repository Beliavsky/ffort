module effects
implicit none
integer::calls=0
contains
impure elemental function value() result(x)
real(8)::x
calls=calls+1
x=3.0d0
end function
function values() result(x)
real::x(2)
error stop 1
x=3.0
end function
end module
program main
use effects
implicit none
real::undefined
integer::idx
real::a(3)
integer,parameter::l=minexponent(1d0),u=maxexponent(1d0)
print *,minexponent(value()),maxexponent(values()),calls,l,u
print *,minexponent(sqrt(undefined)),maxexponent(1.0/undefined)
end program
