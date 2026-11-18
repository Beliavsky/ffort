module statistics_mod
implicit none
integer,parameter :: k=7
type :: dt
integer :: a=k,b=max(2,k+1)
end type dt
end module

use statistics_mod
implicit none
type(dt) :: x
print '(i0,1x,i0)',x%a,x%b
end
