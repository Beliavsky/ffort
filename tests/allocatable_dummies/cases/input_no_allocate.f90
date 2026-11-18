module m

contains
subroutine bad(a)
integer,allocatable,intent(in)::a(:)
allocate(a(1))
end subroutine
end module
program main
use m
integer,allocatable::v(:)
call bad(v)
end program
