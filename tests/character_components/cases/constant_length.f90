module statistics_mod
implicit none
type :: dt
character(len=2+2) :: s
end type dt
end module

use statistics_mod
implicit none
type(dt) :: x, z
x%s="ab"
print*,len(x%s)
end
