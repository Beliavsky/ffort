module types
implicit none
type::dt
real::y=1000.0
end type
end module
program p
use types
implicit none
type(dt)::x,z
z=x
z%y=2.5
print '(2f8.1)',x%y,z%y
end program
