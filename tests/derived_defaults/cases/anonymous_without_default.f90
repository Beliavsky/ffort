module types
implicit none
type::dt
real::y
end type
end module
use types
implicit none
type(dt)::x
x%y=42.0
print '(f5.1)',x%y
end
