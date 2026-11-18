module m

contains
function scale(x) result(y)
integer, intent(in) :: x
integer,parameter :: fac=3
integer :: y
y=x*fac
end function scale
end module m
program main
use m
implicit none

print *, scale(4)
end program main
