module z
type::box
real::x
end type
contains
character(2) function f(b) result(s)
type(box),intent(in)::b
if(b%x/=3.0)stop 1
s="OK"
end function
end module
program p
use z
write(*,"(a)")[f(box(3))]
end program
