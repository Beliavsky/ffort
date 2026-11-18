module m
interface ior
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
print *,ior(7)
end program
