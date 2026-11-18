module m
implicit none

interface operator(+)
module procedure f
end interface
contains
elemental function f(a,b) result(c)
character(*),intent(in)::a
logical,intent(in)::b
integer::c
c=len(a)
if(b)c=c+1
end function
end module
program p
use m
implicit none

print '(i0)', 'abc'+.true.
end program
