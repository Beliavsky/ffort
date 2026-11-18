module m
implicit none

interface operator(+)
module procedure f
end interface
contains
function f(a,b) result(c)
character(*),intent(in)::a
integer,intent(out)::b
integer::c
c=len(a)+b
end function
end module
program p
use m
implicit none

print *, 'a'+1
end program
