module state
implicit none
integer::first=2
integer::counter=first
contains
subroutine change()
counter=3
end subroutine
end module
program main
use state
implicit none
call change()
end program
