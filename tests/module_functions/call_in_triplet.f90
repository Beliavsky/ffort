module m

contains
function nextidx(x) result(y)
integer,intent(in) :: x
integer :: y
y=x+1
end function nextidx
end module m
program main
use m
implicit none
integer :: a(3)
a=4
a(2)=9
print *, a(nextidx(0):nextidx(1))
end program main
