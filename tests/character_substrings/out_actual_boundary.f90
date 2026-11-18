module m
contains
subroutine set(s)
character(*),intent(out)::s
s='a'
end subroutine
end module
program test
use m
implicit none
character(3)::s
s='abc'
call set(s(1:2))
end program
