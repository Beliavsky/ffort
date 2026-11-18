module state
implicit none
integer::counter=8
contains
subroutine change()
integer::counter
counter=2
end subroutine
end module
program main
use state
implicit none
call change()
print *,counter
end program
