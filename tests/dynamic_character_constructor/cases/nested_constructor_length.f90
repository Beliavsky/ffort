module m
implicit none
contains
subroutine f(x)
character(*),intent(in)::x
integer::i,j
character(len(x))::a(4)
a=[([x,x],i=1,2)]
if(any(a/=x))stop 1
write(*,"(*(a))")a
end subroutine
end module
program p
use m
implicit none
call f("Q ")
end program
