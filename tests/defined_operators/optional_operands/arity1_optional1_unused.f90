module ops
implicit none
interface operator(.test.)
module procedure f
end interface
contains
pure integer function f(x) result(y)
integer,intent(in),optional ::x
y=x
end function
end module
program main
use ops
implicit none
print *, 42
end program
