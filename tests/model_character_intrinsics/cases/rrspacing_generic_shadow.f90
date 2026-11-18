module m
implicit none
interface rrspacing
module procedure f
end interface
contains
integer function f(x)
integer,intent(in)::x
f=x+1
end function
end module
program p
use m
implicit none
print *,rrspacing(2)
end program
