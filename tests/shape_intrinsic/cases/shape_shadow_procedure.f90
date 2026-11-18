module m
contains
integer function shape(x)
integer,intent(in)::x
shape=x+10
end function
end module
program p
use m
implicit none
print *, shape(2)
end program
