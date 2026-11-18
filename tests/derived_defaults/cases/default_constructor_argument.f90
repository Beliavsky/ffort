module types
implicit none
type::dt
integer::a=7
end type
contains
subroutine show(v)
type(dt),intent(in)::v
print '(i0)',v%a
end subroutine
end module
program p
use types
implicit none
call show(dt())
end program
