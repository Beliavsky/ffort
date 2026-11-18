module statistics_mod
implicit none
type :: dt
character(len=3) :: s="cat"
end type dt
end module

use statistics_mod
implicit none
type(dt) :: x, z
x=dt()
print "(a)",x%s
end
