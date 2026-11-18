module m
implicit none
contains
subroutine probe(a)
integer,allocatable,intent(inout)::a(:,:,:)
integer::v(max(1,size(a)))
if(size(v)/=1) error stop 1
v=3
end subroutine
end module
program main
use m
implicit none
integer,allocatable::a(:,:,:)
allocate(a(2,0,4))

call probe(a)

print *,1
end
