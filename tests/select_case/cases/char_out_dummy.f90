module m
implicit none
contains
subroutine f(x)
character(len=*),intent(out)::x
x='abcdef'
end subroutine
end module
program p
use m
implicit none
character(3)::x
call f(x)
print '(a)',x
end program
