module m
implicit none
contains
subroutine probe(a)
real,allocatable,intent(in)::a(:,:,:)
integer::v(lbound(a,3):ubound(a,3))
if(lbound(v,1)/=-2.or.ubound(v,1)/=1.or.size(v)/=4) error stop 1
v=0
end subroutine
end module
program main
use m
implicit none
real,allocatable::a(:,:,:)
allocate(a(-1:0,3:5,-2:1))

call probe(a)

print *,1
end
