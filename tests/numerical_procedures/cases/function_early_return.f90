module m
implicit none

contains
integer function f(x) result(y)
integer, intent(in) :: x
if(x<0) then
y=10
return
end if
y=20
end function f
end module m
program main
use m
implicit none

print *,f(-1),f(0)
end program main
