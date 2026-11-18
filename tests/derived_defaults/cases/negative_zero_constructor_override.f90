module types
implicit none
type::dt
real(8)::a=1.0d0
end type
end module
program p
use types
implicit none
type(dt)::x
x=dt(-0.0d0)
print '(es25.17)',x%a
end program
