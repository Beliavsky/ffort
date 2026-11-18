module m

contains
function square(x) result(y)
integer,intent(in) :: x
integer :: y
y=x*x
end function square
function combine(a,b) result(y)
integer,intent(in) :: a,b
integer :: y
y=a*10+b
end function combine
end module m
program main
use m
implicit none

print *, combine(square(2),square(3))
end program main
