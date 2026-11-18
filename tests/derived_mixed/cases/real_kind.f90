module statistics_mod
implicit none
type :: dt
real(8) :: a=1.25_8,b,c=2.5_8
end type dt
end module

use statistics_mod
implicit none
type(dt) :: x
x%b=3.75_8
print '(3f6.2)',x%a,x%b,x%c
end
