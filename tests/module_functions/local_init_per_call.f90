module m

contains
function sometimes(x) result(y)
integer,intent(in) :: x
integer :: y,z
if(x>0) then
z=x
end if
y=z
end function sometimes
end module m
program main
use m
implicit none

print *, sometimes(3)
print *, sometimes(0)
end program main
