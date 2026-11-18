module m
implicit none
integer,allocatable::global(:)
contains
pure subroutine start()
integer,allocatable::local(:)
allocate(local(2),global(2))
end subroutine
end module
program p
use m
implicit none
call start()
end program
