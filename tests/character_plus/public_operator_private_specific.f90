module m
implicit none
private
public::operator(+)
interface operator(+)
module procedure f
end interface
contains
elemental function f(a,b) result(c)
character(*),intent(in)::a
integer,intent(in)::b
integer::c
c=len(a)+b
end function
end module
program p
use m
implicit none

print '(i0)', 'abc'+7
end program
