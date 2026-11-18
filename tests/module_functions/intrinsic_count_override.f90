module m

contains
function count(x) result(y)
integer,intent(in) :: x
integer :: y
y=x+1
end function count
end module m
program main
use m
implicit none

print *, count(3)
end program main
