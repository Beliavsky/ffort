module constants
implicit none
integer,parameter::n=23
end module
module types
use constants,only:n
implicit none
type::dt
integer::a=n
end type
end module
program p
use types
implicit none
type(dt)::x
print '(i0)',x%a
end program
