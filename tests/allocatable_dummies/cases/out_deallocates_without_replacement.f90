module m

contains
subroutine clear(a)
integer,allocatable,intent(out)::a(:)
if(allocated(a)) error stop 1
end subroutine
end module
program main
use m
integer,allocatable::v(:)
allocate(v(2))
v=8
call clear(v)
print *,allocated(v)
end program
