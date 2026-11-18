module state
implicit none
integer::counter(2)
contains
subroutine change()
counter(1)=1
end subroutine
end module
program main
use state
implicit none
call change()
print *,counter(2)
end program
