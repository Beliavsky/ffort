module m

contains
function twice(x) result(y)
real :: x,y
y=2*x
end function twice
end module m
program main
use m
implicit none

print *, twice(2.3)
end program main
