module m
implicit none
private
public :: outer
contains
real function outer(x) result(y)
real, intent(in) :: x
y=inner(x)
end function outer
pure real function inner(x) result(y)
real, intent(in) :: x
y=x*2
end function inner
end module m
program main
use m
implicit none

print *,outer(2.5)
end program main
