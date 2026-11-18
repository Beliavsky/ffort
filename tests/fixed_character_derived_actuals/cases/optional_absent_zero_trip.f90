module z
type::box
integer::x
end type
contains
character(2) function f(b) result(s)
type(box),optional,intent(in)::b
error stop 77
s="NO"
end function
subroutine probe(b)
type(box),optional,intent(in)::b
integer::i
write(*,"(i0)")len([(f(b),i=1,0)])
end subroutine
end module
program p
use z
call probe()
end program
