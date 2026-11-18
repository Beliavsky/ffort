module m
contains
function first(s) result(r)
character(3),intent(in)::s
character(2)::r
r=s(2:)
end function
end module
program test
use m
implicit none
print '(a)',first('abcdef')
end program
