module m

contains
function loopsum(x) result(y)
integer,intent(in) :: x
integer :: y,i
y=0
do i=1,x
y=y+1
end do
end function loopsum
end module m
program main
use m
implicit none

print *, loopsum(10000)
end program main
