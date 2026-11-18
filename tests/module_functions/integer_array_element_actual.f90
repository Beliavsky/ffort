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
integer :: a(2)
a=2
print *, inc(a(1)),a
end program main
