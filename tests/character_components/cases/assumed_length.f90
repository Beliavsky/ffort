module statistics_mod
implicit none
type :: dt
character(len=*) :: s
end type dt
end module

use statistics_mod
implicit none
type(dt) :: x, z
print*,1
end
