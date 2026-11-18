module state
implicit none
integer::counter(0)=1
contains
subroutine change()
counter=2
end subroutine
end module
program main
use state
implicit none
call change()
print *,size(counter),sum(counter)
end program
