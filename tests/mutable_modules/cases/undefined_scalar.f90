module state
implicit none
integer::counter
contains
subroutine change()
counter=1
end subroutine
end module
program main
use state
implicit none
print *,counter
end program
