module m
interface dprod
module procedure f
end interface
contains
integer function f(x)
integer,intent(in)::x
f=x+3
end function
end module
program p
use m
print *,dprod(3)
end program
