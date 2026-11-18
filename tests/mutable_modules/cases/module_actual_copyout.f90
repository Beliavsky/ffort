module state
implicit none
integer::counter=2
contains
subroutine change(x)
integer,intent(inout)::x
x=x+3
end subroutine
end module
program main
use state
implicit none
call change(counter)
print *,counter
end program
