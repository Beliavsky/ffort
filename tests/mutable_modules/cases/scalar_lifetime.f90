module state
implicit none
integer::counter=4
contains
subroutine change()
counter=counter+1
end subroutine
end module
program main
use state
implicit none
call change()
call change()
print *,counter
counter=10
call change()
print *,counter
end program
