module statistics_mod
implicit none
type :: dt
character(len=3) :: s(2)
end type dt
end module

use statistics_mod
implicit none
type(dt) :: x, z
print*,1
end
