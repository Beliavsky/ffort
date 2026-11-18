module statistics_mod
implicit none
type::dt
character(len=3)::s="cat"
end type
contains
subroutine reset(v)
type(dt),intent(out)::v
if(v%s/="cat") error stop "reset"
v%s="a"
end subroutine
end module
program main
use statistics_mod
implicit none
type(dt)::x,z
x%s="dog"
call reset(x)
print '(a)',"["//x%s//"]"
end
