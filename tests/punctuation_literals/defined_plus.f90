module m
implicit none
interface operator(+)
module procedure f
end interface
contains
function f(a,b) result(c)
character(*),intent(in)::a,b
character(len(a)+len(b))::c
c=a//b
end function
end module
program p
use m
implicit none
character(2)::s
s='ab'
print '(a)','['+s+']'
end program
