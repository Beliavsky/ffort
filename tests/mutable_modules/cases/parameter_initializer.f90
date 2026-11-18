module state
implicit none
integer,parameter::base=5
integer::counter=base*2
contains
subroutine change()
counter=counter+base
end subroutine
end module
program main
use state
implicit none
call change()
print *,counter
end program
