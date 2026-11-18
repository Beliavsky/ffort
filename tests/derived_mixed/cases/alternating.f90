module statistics_mod
implicit none
type :: dt
integer :: a,b=8,c,d=10
end type dt
end module

use statistics_mod
implicit none
type(dt) :: x
x%a=1
x%c=3
print '(4(i0,1x))',x%a,x%b,x%c,x%d
end
