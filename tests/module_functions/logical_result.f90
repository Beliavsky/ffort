module m

contains
function positive(x) result(y)
integer,intent(in) :: x
logical :: y
y=x>0
end function positive
end module m
program main
use m
implicit none

print *, positive(2),positive(-1)
end program main
