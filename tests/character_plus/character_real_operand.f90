module m
implicit none

interface operator(+)
module procedure f
end interface
contains
elemental function f(a,b) result(c)
character(*),intent(in)::a
real(8),intent(in)::b
integer::c
c=len(a)+int(b)
end function
end module
program p
use m
implicit none

print '(i0)', 'abc'+7d0
end program
