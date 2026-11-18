module m

contains
function twice(x) result(y)
real,intent(in) :: x
real :: y,a(2)
a=x
y=a(1)
end function twice
end module m
program main
use m
implicit none

print *, twice(2.3)
end program main
