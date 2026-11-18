module statistics_mod
implicit none
type :: dt
integer :: a=7,b=8
end type dt
end module

use statistics_mod
implicit none
type(dt) :: x
x=dt()
print '(i0,1x,i0)',x%a,x%b
end
