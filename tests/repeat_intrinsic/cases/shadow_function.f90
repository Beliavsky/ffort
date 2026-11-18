module m
contains
integer function repeat(x)
integer,intent(in)::x
repeat=x+10
end function
end module
program p
use m
implicit none
print *,repeat(2)
end program
