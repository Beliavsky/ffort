module m
implicit none
contains
subroutine f(x)
character(*),intent(in)::x
integer::i
character(8)::a(2)
a=[(trim(x),i=1,2)]
print "(a)","UNREACHED"
end subroutine
end module
program p
use m
implicit none
call f("ab ")
end program
