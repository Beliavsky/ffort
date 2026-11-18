module state
implicit none
integer::counter=2
contains
subroutine change()
integer::local=2
counter=local
end subroutine
end module
program main
use state
implicit none
call change()
end program
