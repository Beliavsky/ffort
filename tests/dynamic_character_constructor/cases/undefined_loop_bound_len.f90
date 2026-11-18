module m
implicit none
contains
subroutine f(x)
character(*),intent(in)::x
integer::i,n
if(len([(x,i=1,n)])/=len(x))stop 1
print "(a)","OK"
end subroutine
end module
program p
use m
implicit none
call f("abc")
end program
