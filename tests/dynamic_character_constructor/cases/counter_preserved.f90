module m
implicit none
contains
subroutine f(x)
character(*),intent(in)::x
integer::i
character(len(x))::a(2)
i=77
a=[(x,i=1,2)]
if(i/=77.or.any(a/=x))stop 1
print "(a)","OK"
end subroutine
end module
program p
use m
implicit none
call f("a")
end program
