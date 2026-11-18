module statistics_mod
implicit none
type :: dt
integer :: a=7, &
& b, &
& c=9
end type dt
end module

use statistics_mod
implicit none
type(dt) :: x
x%b=8
print '(3(i0,1x))',x%a,x%b,x%c
end
