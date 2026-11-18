module state
implicit none
integer::counter(-2:1,0:1)=3
contains
subroutine change()
counter(-1,1)=8
end subroutine
end module
program main
use state
implicit none
call change()
print *,lbound(counter,1),lbound(counter,2),ubound(counter,1),ubound(counter,2),sum(counter)
end program
