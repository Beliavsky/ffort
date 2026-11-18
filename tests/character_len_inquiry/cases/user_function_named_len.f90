module m
implicit none
contains
integer function len(x) result(n)
integer,intent(in)::x
n=x+100
end function
end module
program p
use m
implicit none
character(7)::s
if(s%len/=7) error stop 1
if(len(2)/=102) error stop 2
end program
