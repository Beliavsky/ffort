module types
implicit none
type::dt
integer::a=7
integer::b
end type
end module
program p
use types
implicit none
type(dt)::x
print '(a)','SAFE'
print '(i0)',x%b
end program
