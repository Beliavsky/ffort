module types
implicit none
type::dt
integer::a=7
end type
contains
subroutine reset(v)
type(dt),intent(out)::v
print '(i0)',v%a
end subroutine
end module
program p
use types
implicit none
type(dt)::x
x%a=99
call reset(x)
print '(i0)',x%a
end program
