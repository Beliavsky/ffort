module m
contains
function f(s) result(r)
character(*),intent(in)::s
character(len(s))::r
r=s
end function
end module
program t
use m
implicit none
character(4)::s
s='abcd'
print '(a)',f(s(2:3))
end program
