module m

contains
subroutine grow(a)
integer,allocatable,intent(inout)::a(:)
integer::fixed(500001)
end subroutine
end module
program main
use m
integer,allocatable::v(:)
allocate(v(500001))
call grow(v)
end program
