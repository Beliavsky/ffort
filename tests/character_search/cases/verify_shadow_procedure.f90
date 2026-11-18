module m
contains
integer function verify(x)
integer,intent(in)::x
verify=x+10
end function
end module
program p
use m
implicit none
print *, verify(2)
end program
