module m
implicit none
contains
subroutine f(x)
character(*),intent(in)::x
integer::i
print *,len([(x//x,i=1,0)])
end subroutine
end module
program p
use m
implicit none
character(32769)::a
call f(a)
end program
