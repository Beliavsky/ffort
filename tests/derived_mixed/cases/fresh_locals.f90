module statistics_mod
implicit none
type :: dt
integer :: a=7,b=8
end type dt
contains
subroutine f()
type(dt)::v
print '(i0,1x,i0)',v%a,v%b
v%a=99
v%b=100
end subroutine
end module

use statistics_mod
implicit none
type(dt) :: x
call f()
call f()
end
