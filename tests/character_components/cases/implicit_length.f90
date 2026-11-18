module statistics_mod
implicit none
type :: dt
character :: s
end type dt
end module

use statistics_mod
implicit none
type(dt) :: x, z
x%s="ab"
print "(a)",x%s
end
