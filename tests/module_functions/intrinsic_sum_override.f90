module m

contains
function sum(x) result(y)
integer,intent(in) :: x
integer :: y
y=x+1
end function sum
end module m
program main
use m
implicit none

print *, sum(3)
end program main
