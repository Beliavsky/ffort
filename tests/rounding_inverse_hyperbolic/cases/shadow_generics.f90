module m
implicit none
interface aint
module procedure f
end interface
interface anint
module procedure f
end interface
interface asinh
module procedure f
end interface
interface acosh
module procedure f
end interface
contains
integer function f(x)
integer,intent(in)::x
f=x+10
end function
end module
program p
use m
implicit none
print *,aint(1),anint(2),asinh(3),acosh(4)
end program
