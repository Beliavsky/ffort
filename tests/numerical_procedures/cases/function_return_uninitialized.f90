module m
implicit none

contains
real function f(x) result(y)
real,intent(in)::x
return
end function f
end module m
program main
use m
implicit none

print *,f(2.0)
end program main
