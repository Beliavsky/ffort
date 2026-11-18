module statistics_mod
implicit none
type :: dt
integer :: a=7,b
end type dt
contains
subroutine reset(v)
type(dt),intent(out)::v
end subroutine
end module

use statistics_mod
implicit none
type(dt) :: x
x%a=99
x%b=10
call reset(x)
print '(i0)',x%a
end
