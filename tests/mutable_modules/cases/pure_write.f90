module state
implicit none
integer::counter=2
contains
pure subroutine change()
counter=3
end subroutine
end module
program main
use state
implicit none
call change()
end program
