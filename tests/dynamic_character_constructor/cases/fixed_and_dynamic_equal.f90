module m
implicit none
contains
subroutine f(x)
character(*),intent(in)::x
character(3)::a(3)
integer::i
a=["abc",(x,i=1,2)]
if(any(a/="abc"))stop 1
print "(a)","OK"
end subroutine
end module
program p
use m
implicit none
call f("abc")
end program
