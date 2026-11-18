module m
contains
subroutine f(n)
integer,intent(in)::n
integer::i
character(n),allocatable::x
if(allocated(x))stop 1
write(*,"(i0)")len(x)
end subroutine
end module
program p
use m
call f(5)
end program
