module m
implicit none
contains
subroutine f(x)
character(*),intent(in)::x
character(len(x))::a(2)
integer::i
a=[(x,i=1,2)]
print "(a)","UNREACHED"
end subroutine
end module
program p
use m
implicit none
character(7)::a
call f(a)
end program
