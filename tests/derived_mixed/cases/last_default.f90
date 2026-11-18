module statistics_mod
implicit none
type :: dt
integer :: a,b=8
end type dt
end module

use statistics_mod
implicit none
type(dt) :: x
print '(i0)',x%b
end
