module m

contains
function fa(x) result(y)
integer, intent(in) :: x
integer :: y,local
local=x+1
y=local
end function fa
function fb(x) result(y)
integer, intent(in) :: x
integer :: y,local
local=x*2
y=fa(local)
end function fb
end module m
program main
use m
implicit none
integer :: x=7,y=8,local=9
print *, fa(2),fb(3),x,y,local
end program main
