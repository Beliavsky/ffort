module m
integer,allocatable::a(:)
contains
pure subroutine bad()
allocate(a(2))
end subroutine
end module
program main
use m
call bad()
end program
