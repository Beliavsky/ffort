module m
implicit none

interface operator(-)
module procedure f
end interface
contains
elemental function f(a,b) result(c)
character(*),intent(in)::a,b
character(len(a)+len(b))::c
c=a//b
end function
end module
program p
use m
implicit none

print *, 'a'-'b'
end program
