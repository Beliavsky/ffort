module statistics_mod
implicit none
type :: dt
real :: y=1000.0
end type dt
end module
use statistics_mod
implicit none
type(dt)::x
print*,x%y
end
