module ops
implicit none
interface operator(.test.)
module procedure f
end interface
contains
pure integer function f(x,z) result(y)
integer,intent(in),optional ::x
integer,intent(in)          ::z
y=x
end function
end module
program main
use ops
implicit none
print *, 2 .test. 3
end program
