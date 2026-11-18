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
type(dt)::x,z
print '(a)','SAFE'
z=x
print '(i0)',z%a
end program
