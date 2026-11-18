module types
implicit none
type::dt
integer::a=7
integer::b
end type
contains
subroutine reset(v)
type(dt),intent(out)::v
print '(i0)',v%a
print '(i0)',v%b
end subroutine
end module
program p
use types
implicit none
type(dt)::x
x%b=99
call reset(x)
end program
