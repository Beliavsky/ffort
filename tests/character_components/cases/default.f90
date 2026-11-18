module statistics_mod
implicit none
type :: dt
character(len=3) :: s="ab"
end type dt
end module

use statistics_mod
implicit none
type(dt) :: x, z
print "(a)", "["//x%s//"]"
end
