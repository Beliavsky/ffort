module statistics_mod
implicit none
type :: dt
character(len=3) :: s
end type dt
end module

use statistics_mod
implicit none
type(dt) :: x, z
x%s=3
end
