module m
implicit none

interface operator(+)
module procedure f
end interface
contains
function f(a) result(c)
character(*),intent(in)::a
character(len(a))::c
c=a
end function
end module
program p
use m
implicit none

print *, +'a'
end program
