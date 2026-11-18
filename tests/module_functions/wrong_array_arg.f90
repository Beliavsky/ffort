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
real :: a(2)
a=1.0
print *, 123
print *, twice(a)
end program main
