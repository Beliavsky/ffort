module state
implicit none
integer::counter=2
contains
subroutine change()
counter=3
end subroutine
end module
program main
use state,only:change
implicit none
print *,counter
end program
