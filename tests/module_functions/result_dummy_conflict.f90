module m

contains
function twice(x) result(x)
real,intent(in) :: x
x=2*x
end function twice
end module m
program main
use m
implicit none

print *, twice(2.3)
end program main
