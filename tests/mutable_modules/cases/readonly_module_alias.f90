module state
implicit none
integer::counter=2
contains
subroutine change(x)
integer,intent(in)::x
print *,x,counter
end subroutine
end module
program main
use state
implicit none
call change(counter)
end program
