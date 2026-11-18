module types
implicit none
type::dt
real::y=1000.0
end type
end module
program p
use types
implicit none
type(dt)::x
x%y=12.5
print '(f6.1)',x%y
end program
