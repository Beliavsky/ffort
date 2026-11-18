module m
implicit none
contains
subroutine probe(a)
integer,allocatable,intent(in)::a(:)
integer::v(lbound(a,1):ubound(a,1))
if(size(v)/=0.or.lbound(v,1)/=1.or.ubound(v,1)/=0) error stop 1
end subroutine
end module
program main
use m
implicit none
integer,allocatable::a(:)
allocate(a(8:3))

call probe(a)

print *,1
end
