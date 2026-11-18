module m

contains
function twice(x) result(y)
real, intent(in) :: x
real :: y
y=2*x
end function twice
function bad(a) result(y)
integer,intent(in) :: a
integer :: y
print *, a
y=a
end function bad
end module m
program main
use m
implicit none

print *, twice(2.3)
end program main
