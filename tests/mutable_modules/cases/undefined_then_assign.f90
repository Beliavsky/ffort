module state
implicit none
integer::counter
contains
subroutine change()
counter=7
end subroutine
end module
program main
use state
implicit none
call change()
print *,counter
end program
