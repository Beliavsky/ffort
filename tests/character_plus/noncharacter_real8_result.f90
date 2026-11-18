module m
implicit none

interface operator(+)
module procedure f
end interface
contains
elemental function f(a,b) result(c)
character(*),intent(in)::a
integer,intent(in)::b
real(8)::c
c=real(len(a)+b,8)
end function
end module
program p
use m
implicit none

print '(f8.2)', 'abc'+7
end program
