module statistics_mod
implicit none
type::dt
character(len=3)::s="cat"
end type
contains
end module
program main
use statistics_mod
implicit none
type(dt)::x,z
character(len=3)::s(2)
x%s="dog"
s=[x%s,z%s]
print "(a)",s
end
