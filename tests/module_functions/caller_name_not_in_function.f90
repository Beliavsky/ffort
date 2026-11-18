module m

contains
function twice(x) result(y)
real, intent(in) :: x
real :: y
y=x+caller
end function twice
end module m
program main
use m
implicit none
real :: caller=7.0
print *, twice(2.3)
end program main
