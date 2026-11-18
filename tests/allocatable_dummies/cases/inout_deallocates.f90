module m

contains
subroutine clear(a)
integer,allocatable,intent(inout)::a(:)
if(allocated(a)) deallocate(a)
end subroutine
end module
program main
use m
integer,allocatable::v(:)
call clear(v)
print *,allocated(v)
allocate(v(0))
call clear(v)
print *,allocated(v)
end program
