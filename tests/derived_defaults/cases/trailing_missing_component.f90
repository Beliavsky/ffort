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
x=dt(2)
end program
