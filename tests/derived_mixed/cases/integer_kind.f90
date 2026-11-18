module statistics_mod
implicit none
type :: dt
integer(8) :: a=2147483648_8,b=2147483649_8
end type dt
end module

use statistics_mod
implicit none
type(dt) :: x
print '(i0,1x,i0)',x%a,x%b
end
