module m
contains
integer function scan(x)
integer,intent(in)::x
scan=x+10
end function
end module
program p
use m
implicit none
print *, scan(2)
end program
