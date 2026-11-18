module m
implicit none
contains
subroutine probe(a)
integer,allocatable,intent(in)::a(:)
integer::v(lbound(a,1):ubound(a,1))
if(lbound(v,1)/=-2.or.ubound(v,1)/=1) error stop 1
v=7
if(sum(v)/=28) error stop 2
end subroutine
end module
program main
use m
implicit none
integer,allocatable::a(:)
allocate(a(-2:1))

call probe(a)

print *,1
end
