module z
type::box
integer::x,y
end type
contains
character(2) function f(b) result(s)
type(box),intent(in)::b
error stop 77
s="NO"
end function
end module
program p
use z
type(box)::b
b%x=3
write(*,"(i0)")len([f(b)])
end program
