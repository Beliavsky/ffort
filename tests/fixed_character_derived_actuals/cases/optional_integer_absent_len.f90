module z
contains
character(2) function f(n) result(s)
integer,optional,intent(in)::n
error stop 77
s="NO"
end function
subroutine probe(n)
integer,optional,intent(in)::n
integer::i
write(*,"(i0)")len([f(n)])
end subroutine
end module
program p
use z
call probe()
end program
