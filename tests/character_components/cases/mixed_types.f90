module statistics_mod
implicit none
type :: dt
integer :: i
character(len=3) :: s
real :: r
end type dt
end module

use statistics_mod
implicit none
type(dt) :: x, z
x=dt(4,"xy",2.5)
print*,x%i,x%r
print "(a)","["//x%s//"]"
end
