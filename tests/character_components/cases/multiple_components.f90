module statistics_mod
implicit none
type :: dt
character(len=3) :: s,t
end type dt
end module

use statistics_mod
implicit none
type(dt) :: x, z
x%s="a"
x%t="b"
print "(a)",x%s//x%t
end
