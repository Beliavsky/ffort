module m
interface eoshift
module procedure f
end interface
contains
integer function f(x)
integer,intent(in)::x
f=x+2
end function
end module
program p
use m
implicit none
write(*,'(i0)')eoshift(5)
end program
