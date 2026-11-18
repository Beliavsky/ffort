module types
implicit none
type::dt
integer::a=7
end type
contains
pure function make() result(r)
type(dt)::r
end function
end module
program p
use types
implicit none
type(dt)::x
x=make()
print '(i0)',x%a
end program
