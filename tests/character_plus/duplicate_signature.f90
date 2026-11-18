module m
implicit none

interface operator(+)
module procedure f,g
end interface
contains
elemental function f(a,b) result(c)
character(*),intent(in)::a
integer,intent(in)::b
integer::c
c=len(a)+b
end function
elemental function g(a,b) result(c)
character(*),intent(in)::a
integer,intent(in)::b
integer::c
c=len(a)+b
end function
end module
program p
use m
implicit none

print *,1
end program
