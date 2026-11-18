module m

contains
function twice(x) result(y)
real, intent(in) :: x
real :: y
y=2*x
end function twice
end module m
program main
use m
implicit none
real :: a=twice(2.3)
print *, a
end program main
