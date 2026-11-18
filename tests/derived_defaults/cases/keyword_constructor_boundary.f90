module types
implicit none
type::dt
integer::a=7
end type
end module
program p
use types
implicit none
type(dt)::x
x=dt(a=8)
end program
