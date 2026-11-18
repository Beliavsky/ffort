module m

contains
function choose(x,t) result(y)
integer, intent(in) :: x
logical, intent(in) :: t
real :: y
if(t) then
y=real(x)/2
else
y=-real(x)
end if
end function choose
end module m
program main
use m
implicit none

print *, choose(7,.true.),choose(7,.false.)
end program main
