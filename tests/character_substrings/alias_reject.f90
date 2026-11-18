module m
contains
subroutine set(a,b)
character(*),intent(in)::a
character(*),intent(out)::b
b=a
end subroutine
end module
program test
use m
implicit none
character(3)::s
s='abc'
call set(s(1:2),s)
end program
