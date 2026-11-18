module m

contains
function add1(x) result(y)
integer,intent(in) :: x
integer :: y
y=x+1
end function add1
end module m
program main
use m
implicit none
integer :: i,s
s=0
do i=1,100
s=s+add1(i)
end do
print *, s
end program main
