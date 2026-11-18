module m
implicit none
contains
subroutine probe(a)
integer,allocatable,intent(inout)::a(:)
integer::v(size(a))
v=3
a=[7,8]
if(size(v)/=4.or.sum(v)/=12) error stop 1
end subroutine
end module
program main
use m
implicit none
integer,allocatable::a(:)
allocate(a(4))

call probe(a)
if(size(a)/=2.or.any(a/=[7,8])) error stop 2
print *,1
end
