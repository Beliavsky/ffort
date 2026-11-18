module m
contains
integer function f(x) result(shape)
integer,intent(in)::x
shape=x+1
end function
end module
program p
use m
implicit none
print *,f(9)
end program
