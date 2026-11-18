module m
implicit none

interface operator(+)
module procedure f
end interface
contains
elemental function f(a,b) result(c)
integer,intent(in)::a
integer,intent(in)::b
integer::c
c=a+b
end function
end module
program p
use m
implicit none

print *,1+2
end program
