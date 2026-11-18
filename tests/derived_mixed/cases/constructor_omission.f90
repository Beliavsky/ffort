module statistics_mod
implicit none
type :: dt
integer :: a,b=8
end type dt
end module

use statistics_mod
implicit none
type(dt) :: x
x=dt(2)
print '(i0,1x,i0)',x%a,x%b
end
