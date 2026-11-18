module m
contains
subroutine bad(a)
integer,allocatable,intent(inout)::a(:)
end subroutine
end module
program main
use m
end program
