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
integer :: i,n
n=0
do i=1,100
n=n+loopsum(2)
end do
print *, n
end program main
