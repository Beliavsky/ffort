module model_effects
implicit none
integer :: calls=0
contains
impure elemental function value() result(x)
real(8) :: x
calls=calls+1
x=3.0d0
end function
function values() result(x)
real :: x(2)
error stop 1
x=3.0
end function
end module
program model_no_evaluation
use model_effects
implicit none
real(8),parameter::e=epsilon(value()),h=huge(value())
real :: undefined
integer :: idx
print *,epsilon(value()),tiny(values()),huge(value()),radix(values()),calls
print *,epsilon(1.0/undefined),tiny(sqrt(undefined)),huge(undefined+1.0),radix(1/idx)
print *,calls,e,h
end program
