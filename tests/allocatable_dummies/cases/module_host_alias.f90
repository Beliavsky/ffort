module m
integer,allocatable::v(:)
contains
subroutine bad(a)
integer,allocatable,intent(out)::a(:)
a=[1]
if(allocated(v)) error stop 1
end subroutine
end module
program main
use m

call bad(v)
end program
