module m
implicit none
contains
subroutine probe(a)
character(7),allocatable,intent(in)::a(:)
integer::v(size(a))
if(size(v)/=2) error stop 1
v=9
end subroutine
end module
program main
use m
implicit none
character(7),allocatable::a(:)
allocate(a(2))

call probe(a)

print *,1
end
