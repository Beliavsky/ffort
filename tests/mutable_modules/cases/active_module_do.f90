module state
implicit none
integer::counter
contains
subroutine change()
counter=99
end subroutine
end module
program main
use state
implicit none
do counter=1,2
call change()
end do
end program
