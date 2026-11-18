module state
implicit none
integer::counter=0
contains
subroutine change()
counter=counter+1
call second()
end subroutine
subroutine second()
counter=counter+10
end subroutine
end module
program main
use state
implicit none
call change()
call change()
print *,counter
end program
