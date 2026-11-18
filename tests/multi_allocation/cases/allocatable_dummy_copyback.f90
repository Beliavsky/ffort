module m
implicit none
contains
subroutine start(a,b)
integer,allocatable,intent(inout)::a(:),b(:)
allocate(a(-1:1),b(2))
a=3
b=4
end subroutine
subroutine finish(a,b)
integer,allocatable,intent(inout)::a(:),b(:)
deallocate(a,b)
end subroutine
end module
program p
use m
implicit none
integer,allocatable::a(:),b(:)
call start(a,b)
print *,sum(a),sum(b),lbound(a,1)
call finish(a,b)
print *,allocated(a),allocated(b)
end program
