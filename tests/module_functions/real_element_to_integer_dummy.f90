module m

contains
function inc(x) result(y)
integer,intent(in) :: x
integer :: y
y=x+1
end function inc
end module m
program main
use m
implicit none
real :: a(2)
a=2.5
print *, 123
print *, inc(a(1))
end program main
