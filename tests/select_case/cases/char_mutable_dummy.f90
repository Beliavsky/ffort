module m
implicit none
contains
subroutine f(x)
character(len=*),intent(inout)::x
x='q'
end subroutine
end module
program p
use m
implicit none
character(3)::x
x='ABC'
call f(x)
print '(a)',x
end program
