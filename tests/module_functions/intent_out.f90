module m

contains
function twice(x) result(y)
real,intent(out) :: x
real :: y
x=3.0
y=x
end function twice
end module m
program main
use m
implicit none
real :: a
print *, twice(a)
end program main
