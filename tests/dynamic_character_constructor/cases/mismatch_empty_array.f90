module m
contains
subroutine f(x,z)
character(*),intent(in)::x(:),z
character(8)::a(1)
a=[x,z]
end subroutine
end module
program p
use m
character(7)::x(0)
call f(x,"bb")
end program
