module statistics_mod
implicit none
type :: dt
character(len=0) :: s
end type dt
end module

use statistics_mod
implicit none
type(dt) :: x, z
x%s = "abc"
print*,len(x%s)
print "(a)", "["//x%s//"]"
end
