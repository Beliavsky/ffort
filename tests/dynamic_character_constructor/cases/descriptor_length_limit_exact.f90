module m
implicit none
contains
subroutine f(x)
character(*),intent(in)::x
integer::i
if(len([(x,i=1,0)])/=65536)stop 1
print "(a)","OK"
end subroutine
end module
program p
use m
implicit none
character(65536)::a
call f(a)
end program
