module m

contains
function twice(x) result(y)
real, intent(in) :: x
real :: y
x=3.0
y=x
end function twice
end module m
program main
use m
implicit none

print *, twice(2.3)
end program main
