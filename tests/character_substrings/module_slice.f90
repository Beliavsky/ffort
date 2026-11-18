module m
implicit none
character(*),parameter::s='abcd'
contains
function first() result(r)
character(2)::r
r=s(2:3)
end function
end module
program test
use m
implicit none
print '(a)',first()//s(4:)
end program
