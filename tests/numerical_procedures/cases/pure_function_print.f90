module m
implicit none

contains
pure real function f(x) result(y)
real,intent(in)::x
print *,x
y=x
end function f
end module m
program main
use m
implicit none

print *,777
print *,f(1.0)
end program main
