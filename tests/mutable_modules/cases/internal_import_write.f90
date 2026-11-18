module state
integer::counter=2
end module
program main
use state,only:counter
call change()
print *,counter
contains
subroutine change()
counter=counter+3
end subroutine
end program
