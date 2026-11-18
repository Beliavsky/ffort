module m

contains
recursive function cycle(x) result(y)
integer,intent(in) :: x
integer :: y
if(x>0) then
y=cycle(x-1)
else
y=0
end if
end function cycle
end module m
program main
use m
implicit none

print *, cycle(3)
end program main
