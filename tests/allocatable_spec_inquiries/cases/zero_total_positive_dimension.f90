module m
implicit none
contains
subroutine probe(a)
integer,allocatable,intent(in)::a(:,:)
integer::v(lbound(a,2):ubound(a,2))
if(size(v)/=3.or.lbound(v,1)/=-2) error stop 1
v=0
end subroutine
end module
program main
use m
implicit none
integer,allocatable::a(:,:)
allocate(a(5:4,-2:0))

call probe(a)

print *,1
end
