module m
interface acos
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
print *,acos(3)
end program
