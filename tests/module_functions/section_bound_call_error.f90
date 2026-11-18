module m

contains
function inv(x) result(y)
integer,intent(in) :: x
integer :: y
y=10/x
end function inv
end module m
program main
use m
implicit none
integer :: a(3)
a=1
print *, a
a(1:inv(0))=2
end program main
