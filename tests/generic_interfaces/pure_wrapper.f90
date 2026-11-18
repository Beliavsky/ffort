module ops
implicit none

interface test
module procedure a,b
end interface
contains
pure integer function a(x) result(y)
integer,intent(in)::x
y=2*x
end function
pure real function b(x) result(y)
real,intent(in)::x
y=2*x
end function
pure integer function wrap(x) result(y)
integer,intent(in)::x
y=test(x)
end function
end module
program main
use ops
implicit none
print *,wrap(3)
end program
