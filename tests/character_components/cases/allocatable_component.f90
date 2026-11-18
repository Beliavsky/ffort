module statistics_mod
implicit none
type :: dt
character(len=:),allocatable :: s
end type dt
end module

use statistics_mod
implicit none
type(dt) :: x, z
print*,1
end
