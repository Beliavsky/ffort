module m
implicit none
contains
function probe(a) result(v)
integer,allocatable,intent(in)::a(:)
integer::v(size(a))
v=7
end function
end module
program main
use m
implicit none
integer,allocatable::a(:)
integer::v(3)
allocate(a(3))
v=probe(a)
if(any(v/=[7,7,7])) error stop 1
print *,1
end
