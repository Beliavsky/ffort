module m
contains
integer function parity(x)
integer,intent(in)::x
parity=x+10
end function
end module
program p
use m
implicit none
print *,parity(3)
end program
