module state
implicit none
integer,allocatable::counter(:)
contains
subroutine change()
continue
end subroutine
end module
program main
use state
implicit none
print *,1
end program
