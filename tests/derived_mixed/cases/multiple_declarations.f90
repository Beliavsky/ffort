module statistics_mod
implicit none
type :: dt
integer :: a=7,b
real :: c,d=2.5
logical :: yes=.true.,no
end type dt
end module

use statistics_mod
implicit none
type(dt) :: x
x%b=8
x%c=1.5
x%no=.false.
print '(2(i0,1x),2f5.1,2l2)',x%a,x%b,x%c,x%d,x%yes,x%no
end
