module m

contains
function ssq(n) result(y)
integer, intent(in) :: n
integer :: y,i
y=0
do i=1,n
if(mod(i,2)==0) then
y=y+i*i
else
y=y+i
end if
end do
end function ssq
end module m
program main
use m
implicit none

print *, ssq(4),ssq(0),ssq(2)
end program main
