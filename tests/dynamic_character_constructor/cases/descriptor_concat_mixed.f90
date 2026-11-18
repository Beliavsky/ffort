module m
implicit none
contains
subroutine f(x)
character(*),intent(in)::x
integer::i
character(len(x)+1)::a(2)
a=[(x//"!",i=1,2)]
write(*,"(*(a))")a
end subroutine
end module
program p
use m
implicit none
call f("ab")
end program
