module m
implicit none
contains
function f(x) result(r)
character(len=*),intent(in)::x
character(len=3)::r
r=x
end function
end module
program p
use m
implicit none
print *,f('ABCDE')
end program
