module types
implicit none
type::dt
integer::a=7
end type
contains
subroutine change(v)
type(dt),intent(inout)::v
v%a=v%a+1
end subroutine
end module
program p
use types
implicit none
type(dt)::x
x%a=99
call change(x)
print '(i0)',x%a
end program
