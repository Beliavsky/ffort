module m
contains
subroutine f(x)
character(*),allocatable,intent(in)::x
integer::i
if(allocated(x))stop 1
write(*,"(i0)")len([x])
end subroutine
end module
program p
use m
character(5),allocatable::x
call f(x)
end program
