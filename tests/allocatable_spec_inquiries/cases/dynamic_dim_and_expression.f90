module m
implicit none
contains
subroutine probe(a,d)
integer,allocatable,intent(inout)::a(:,:)
integer,intent(in)::d
integer::v(max(1,size(a,d)+lbound(a,d)-1))
if(size(v)/=5) error stop 1
v=0
end subroutine
end module
program main
use m
implicit none
integer,allocatable::a(:,:)
allocate(a(2,3:5))
call probe(a,2)
print *,1
end
