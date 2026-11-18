module statistics_mod
implicit none
type::dt
character(len=3)::s="cat"
end type
contains
subroutine update(v)
type(dt),intent(inout)::v
v%s="fox"
end subroutine
end module
program main
use statistics_mod
implicit none
type(dt)::x,z
call update(x)
print '(a)',x%s
end
