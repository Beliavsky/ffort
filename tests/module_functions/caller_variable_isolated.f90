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
real :: x,y
x=2.3
y=100.0
print *, twice(x),x,y
x=4.0
print *, twice(x),x,y
end program main
