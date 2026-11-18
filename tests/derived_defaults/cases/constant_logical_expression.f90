module types
implicit none
type::dt
logical::ok=(3<4).and..true.
end type
end module
program p
use types
implicit none
type(dt)::x
print '(l1)',x%ok
end program
