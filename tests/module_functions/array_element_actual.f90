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
real :: a(-1:1)
a=2.5
a(0)=3.0
print *, twice(a(-1)),twice(a(0)),a
end program main
