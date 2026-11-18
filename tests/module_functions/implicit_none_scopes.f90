module m
implicit none
contains
function twice(x) result(y)
implicit none
real, intent(in) :: x
real :: y
y=2*x
end function twice
end module m
program main
use m
implicit none

print *, twice(2.3)
end program main
