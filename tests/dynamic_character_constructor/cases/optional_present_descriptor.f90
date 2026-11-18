module m
contains
subroutine f(x)
character(*),optional,intent(in)::x
integer::i
if(present(x))then
 if(len([(x,i=1,0)])/=3)stop 1
end if
print "(a)","OK"
end subroutine
end module
program p
use m
call f("abc")
end program
