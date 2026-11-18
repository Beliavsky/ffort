module state
implicit none
integer::counter(3)=[2,3,4]
contains
subroutine change()
counter(2:3)=counter(1:2)
end subroutine
end module
program main
use state
implicit none
call change()
print *,counter
end program
