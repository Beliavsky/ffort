module m
contains
subroutine f(x,z)
character(*),intent(in)::x,z
integer::i
character(8)::a(1)
a=[(x,i=1,0),z]
end subroutine
end module
program p
use m
call f("a","bb")
end program
