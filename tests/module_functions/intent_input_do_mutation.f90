module m

contains
function fun(x) result(y)
integer,intent(in) :: x
integer :: y
y=0
do x=1,3
y=y+x
end do
end function fun
end module m
program main
use m
implicit none

print *, fun(2)
end program main
