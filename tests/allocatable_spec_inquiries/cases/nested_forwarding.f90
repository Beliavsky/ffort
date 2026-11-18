module m
implicit none
contains
subroutine inner(a)
integer,allocatable,intent(inout)::a(:)
integer::v(size(a))
if(size(v)/=3) error stop 1
v=2
a=8
end subroutine
subroutine outer(a)
integer,allocatable,intent(inout)::a(:)
integer::v(size(a))
v=9
call inner(a)
if(size(v)/=3.or.any(v/=9)) error stop 2
end subroutine
end module
program main
use m
implicit none
integer,allocatable::a(:)
allocate(a(3))
call outer(a)
if(any(a/=8)) error stop 3
print *,1
end
