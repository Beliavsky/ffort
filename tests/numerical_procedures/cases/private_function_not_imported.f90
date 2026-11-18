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
use m
implicit none

print *,777
print *,hidden(1.0)
end program main
