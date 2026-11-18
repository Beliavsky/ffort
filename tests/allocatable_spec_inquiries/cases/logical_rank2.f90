module m
implicit none
contains
subroutine probe(a)
logical,allocatable,intent(inout)::a(:,:)
integer::v(size(a,1),size(a,2))
if(any(shape(v)/=[2,3])) error stop 1
v=1
if(sum(v)/=6) error stop 2
end subroutine
end module
program main
use m
implicit none
logical,allocatable::a(:,:)
allocate(a(2,3))

call probe(a)

print *,1
end
