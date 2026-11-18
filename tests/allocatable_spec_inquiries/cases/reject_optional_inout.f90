module m
implicit none
contains
subroutine probe(a)
integer,allocatable,intent(inout),optional::a(:)
integer::v(size(a))
v=0
end subroutine
end module
program main
use m
implicit none
integer,allocatable::a(:)
allocate(a(2))
call probe(a)
end
