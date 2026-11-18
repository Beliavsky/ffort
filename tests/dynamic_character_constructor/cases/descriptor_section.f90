module m
implicit none
contains
subroutine f(x)
character(*),intent(in)::x(:)
integer::i
character(2)::a(4)
a=[(x(:),i=1,2)]
write(*,"(*(a))")a
end subroutine
end module
program p
use m
implicit none
call f(["ab","cd"])
end program
