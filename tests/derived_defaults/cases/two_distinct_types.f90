module types
implicit none
type::first
integer::a=7
end type
type::second
integer::a=9
end type
end module
program p
use types
implicit none
type(first)::x
type(second)::y
print '(2i2)',x%a,y%a
end program
