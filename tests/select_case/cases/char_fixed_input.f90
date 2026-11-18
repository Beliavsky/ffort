module m
implicit none
contains
subroutine f(x)
character(2),intent(in)::x
print *,x
end subroutine
end module
program p
use m
implicit none
call f('ABCDE')
end program
