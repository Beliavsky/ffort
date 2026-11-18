module types
implicit none
type::dt
real(8)::a=1.5d0
end type
end module
program p
use types
implicit none
type(dt)::x
print '(f6.2)',x%a
end program
