module state
implicit none
integer::counter=2
contains
subroutine change(x)
integer,intent(out)::x
end subroutine
end module
program main
use state
implicit none
call change(counter)
print *,counter
end program
