module types
implicit none
type::dt
integer(8)::a=3000000000_8
end type
end module
program p
use types
implicit none
type(dt)::x
print '(i0)',x%a
end program
