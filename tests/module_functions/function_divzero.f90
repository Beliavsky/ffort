module m

contains
function inv(x) result(y)
integer,intent(in) :: x
integer :: y
y=10/x
end function inv
end module m
program main
use m
implicit none

print *, inv(0)
end program main
