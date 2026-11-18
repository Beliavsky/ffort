module m
implicit none

interface operator(+)
module procedure f
end interface
contains
function f(a,b) result(c)
character(*),intent(in)::a(:)
integer,intent(in)::b
integer::c
c=size(a)+b
end function
end module
program p
use m
implicit none

print '(i0)', [character(2)::'a','b']+7
end program
