module statistics_mod
implicit none
type :: dt
logical :: a=.true.,b,c=.false.
end type dt
end module

use statistics_mod
implicit none
type(dt) :: x
x%b=.true.
print '(3l2)',x%a,x%b,x%c
end
