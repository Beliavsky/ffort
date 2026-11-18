module m

contains
function outer(x) result(y)
integer, intent(in) :: x
integer :: y
y=inner(x)+1
end function outer
function inner(x) result(y)
integer, intent(in) :: x
integer :: y
y=x*3
end function inner
end module m
program main
use m
implicit none

print *, outer(4)
end program main
