module statistics_mod
implicit none
type::dt
character(len=3)::s="cat"
end type
contains
function make() result(v)
type(dt)::v
v%s="owl"
end function
end module
program main
use statistics_mod
implicit none
type(dt)::x,z
x=make()
z=x
x%s="dog"
print '(a)',x%s//z%s
end
