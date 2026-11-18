module first
integer::counter=2
end module
module second
use first,only:counter
contains
subroutine change()
counter=counter+3
end subroutine
end module
program main
use first,only:counter
use second,only:change
call change()
print *,counter
end program
