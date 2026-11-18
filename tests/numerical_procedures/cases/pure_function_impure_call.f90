module m
implicit none

contains
pure real function f(x) result(y)
real,intent(in)::x
y=g(x)
end function f
real function g(x) result(y)
real,intent(in)::x
y=x
end function g
end module m
program main
use m
implicit none

print *,777
print *,f(1.0)
end program main
