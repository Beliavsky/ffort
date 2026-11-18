module m
implicit none
contains
subroutine probe(a)
integer(8),allocatable,intent(inout)::a(:,:,:)
integer::v(size(a,1),size(a,2),size(a,3))
v=2
deallocate(a)
allocate(a(1,1,1))
a=9_8
if(any(shape(v)/=[2,3,4]).or.v(2,3,4)/=2) error stop 1
end subroutine
end module
program main
use m
implicit none
integer(8),allocatable::a(:,:,:)
allocate(a(2,3,4))

call probe(a)

print *,1
end
