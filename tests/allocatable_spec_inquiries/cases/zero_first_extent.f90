module m
implicit none
contains
subroutine probe(a)
integer,allocatable,intent(inout)::a(:,:)
logical::v(size(a,1))
if(size(v)/=0) error stop 1
v=.true.
if(.not.all(v)) error stop 2
end subroutine
end module
program main
use m
implicit none
integer,allocatable::a(:,:)
allocate(a(0,3))

call probe(a)

print *,1
end
