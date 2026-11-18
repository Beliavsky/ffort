module m
implicit none
contains
subroutine f(x)
character(3),intent(inout)::x
x='Z'
end subroutine
end module
program p
use m
implicit none
character(3)::x
x='ABC'
call f(x)
print *,x
end program
