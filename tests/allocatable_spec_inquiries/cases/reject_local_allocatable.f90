module m
implicit none
contains
subroutine probe()
integer,allocatable::a(:)
integer::v(size(a))
v=0
end subroutine
end module
program main
use m
implicit none

call probe()
end
