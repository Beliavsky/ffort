module m
implicit none
interface new_line
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
print *,new_line(2)
end program
