module m

contains
function loop(x) result(y)
integer,intent(in) :: x
integer :: y
y=loop(x)
end function loop
end module m
program main
use m
implicit none

print *, loop(3)
end program main
