module m
implicit none
private
public::host
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
integer function host() result(y)
y="abc"+7
end function
end module
program p
use m,only:host
implicit none

print '(i0)',host()
end program
