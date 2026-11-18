module m
implicit none
type::box
integer::len
end type
end module
program p
use m
implicit none
type(box)::x
x%len=9
if(x%len/=9) error stop 1
end program
