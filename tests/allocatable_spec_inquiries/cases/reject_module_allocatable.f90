module m
integer,allocatable::a(:)
contains
subroutine probe()
integer::v(size(a))
v=0
end subroutine
end module
program main
use m
allocate(a(2))
call probe()
end
