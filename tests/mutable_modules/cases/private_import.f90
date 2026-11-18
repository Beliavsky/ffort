module state
implicit none
private
public::change
integer::counter=2
contains
subroutine change()
counter=3
end subroutine
end module
program main
use state
implicit none
print *,counter
end program
