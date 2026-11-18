module m

contains
function twice(x)
real,intent(in) :: x
real :: twice
twice=2*x
end function twice
end module m
program main
use m
implicit none

print *, twice(2.3)
end program main
