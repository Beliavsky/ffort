module m
implicit none
contains
subroutine probe(a)
integer,allocatable,intent(in)::a(:,:,:)
logical::v(size(a))
if(size(v)/=24) error stop 1
v=.true.
if(count(v)/=24) error stop 2
end subroutine
end module
program main
use m
implicit none
integer,allocatable::a(:,:,:)
allocate(a(2,3,4))

call probe(a)

print *,1
end
