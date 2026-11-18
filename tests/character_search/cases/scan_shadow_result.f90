module m
contains
integer function f(x) result(scan)
integer,intent(in)::x
scan=x+1
end function
end module
program p
use m
implicit none
print *,f(9)
end program
