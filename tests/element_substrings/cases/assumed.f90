module m
contains
subroutine f(x)
character(*),intent(inout)::x(:)
x(2)(2:3)=x(1)(3:4)
print '(a)',x(2)(:)
end subroutine
end module
use m
implicit none
character(4)::x(2)=['abcd','wxyz']
call f(x)
end
