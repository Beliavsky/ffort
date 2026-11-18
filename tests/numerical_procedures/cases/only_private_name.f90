module m
implicit none
private
contains
real function hidden(x) result(y)
real,intent(in)::x
y=x
end function hidden
end module m
program main
use m, only : hidden
implicit none

print *,777
end program main
