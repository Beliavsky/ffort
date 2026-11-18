module m
implicit none
contains
subroutine f(x)
character(*),intent(in)::x
integer::i,j
if(size([([(x,j=1,0)],i=1,2)])/=0)stop 1
if(len([([(x,j=1,0)],i=1,2)])/=len(x))stop 2
print "(a)","OK"
end subroutine
end module
program p
use m
implicit none
call f("abc")
end program
