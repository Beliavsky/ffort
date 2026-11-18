module m
implicit none
type::box
integer::n
end type
end module
program p
use m
implicit none
type(box)::x
x%n=9
if(x%n/=9) error stop 1
end program
