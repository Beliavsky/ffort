module m

contains
function half(x) result(y)
real,intent(in) :: x
integer :: y
y=x/2
end function half
end module m
program main
use m
implicit none

print *, half(7.9)
end program main
