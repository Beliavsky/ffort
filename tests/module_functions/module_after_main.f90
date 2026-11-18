program main
use m
print *, twice(2.3)
end program main
module m
contains
function twice(x) result(y)
real, intent(in) :: x
real :: y
y=2*x
end function twice
end module m
