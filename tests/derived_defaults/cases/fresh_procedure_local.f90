module types
implicit none
type::dt
integer::a=7
end type
contains
subroutine show()
type(dt)::x
print '(i0)',x%a
x%a=99
end subroutine
end module
program p
use types
implicit none
call show()
call show()
end program
