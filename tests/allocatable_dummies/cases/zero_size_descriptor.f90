module m

contains
subroutine touch(a)
integer,allocatable,intent(inout)::a(:,:)
if(.not.allocated(a)) error stop 1
print *,size(a),size(a,2),lbound(a,2),ubound(a,2)
a=8
end subroutine
end module
program main
use m
integer,allocatable::v(:,:)
allocate(v(-1:-2,4:6))
call touch(v)
print *,allocated(v),size(v)
end program
