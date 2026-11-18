module statistics_mod
implicit none
type::dt
character(len=3)::s="cat"
end type
contains
function make(text) result(v)
character(len=*),intent(in)::text
type(dt)::v,local
if(local%s/="cat".or.v%s/="cat")error stop "fresh"
local%s=text
v=local
end function
end module
program main
use statistics_mod
implicit none
type(dt)::x,z
x=make("dog")
z=make("owl")
print '(a)',x%s//z%s
end
