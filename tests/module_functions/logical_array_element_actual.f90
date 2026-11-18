module m

contains
function invert(x) result(y)
logical,intent(in) :: x
logical :: y
y=.not.x
end function invert
end module m
program main
use m
implicit none
logical :: a(2)
a=.true.
print *, invert(a(1)),a
end program main
