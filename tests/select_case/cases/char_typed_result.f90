module m
implicit none
contains
character(3) function f(x) result(r)
character(*),intent(in)::x
r=x
end function
end module
program p
use m
implicit none
print *,f('ABCDE')
end program
