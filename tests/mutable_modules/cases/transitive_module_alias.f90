module state
implicit none
integer::counter=2
contains
subroutine change(x)
integer,intent(inout)::x
call second(x)
end subroutine
subroutine second(y)
integer,intent(inout)::y
y=y+counter
end subroutine
end module
program main
use state
implicit none
call change(counter)
end program
