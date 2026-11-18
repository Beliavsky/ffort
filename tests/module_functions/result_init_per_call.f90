module m

contains
function sometimes(x) result(y)
integer,intent(in) :: x
integer :: y
if(x>0) then
y=x
end if
end function sometimes
end module m
program main
use m
implicit none

print *, sometimes(3)
print *, sometimes(0)
end program main
