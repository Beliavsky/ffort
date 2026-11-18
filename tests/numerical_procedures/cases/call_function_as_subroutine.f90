module m
implicit none

contains
real function f(x) result(y)
real,intent(in)::x
y=x
end function f
end module m
program main
use m
implicit none

print *,777
call f(1.0)
end program main
