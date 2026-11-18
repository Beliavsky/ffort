module m

contains
function square(x) result(y)
integer,intent(in) :: x
integer :: y
y=x*x
end function square
end module m
program main
use m
implicit none

print *, square(50000)
end program main
