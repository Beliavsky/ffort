module types
implicit none
type::dt
integer::a=7
integer::b
integer::c=9
end type
end module
program p
use types
implicit none
type(dt)::x
x=dt(2,4)
print '(3i3)',x%a,x%b,x%c
end program
