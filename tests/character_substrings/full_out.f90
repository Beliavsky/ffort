module m
contains
subroutine fill(s)
character(*),intent(out)::s
s(:)='hello'
end subroutine
end module
program test
use m
implicit none
character(4)::s
call fill(s)
print '(a)',s
end program
