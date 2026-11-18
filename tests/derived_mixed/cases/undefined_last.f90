module statistics_mod
implicit none
type :: dt
integer :: a=7,b
end type dt
end module

use statistics_mod
implicit none
type(dt) :: x
print*,x%b
end
