module m
implicit none
character(4)::s
contains
subroutine set()
s='abcd'
s(2:3)='z'
end subroutine
end module
program test
use m
implicit none
call set()
print '(a)',s(1:)
end program
