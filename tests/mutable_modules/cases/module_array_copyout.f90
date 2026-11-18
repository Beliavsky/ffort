module state
implicit none
integer::counter(4)=[1,2,3,4]
contains
subroutine change(x)
integer,intent(inout)::x(:)
x=x+3
end subroutine
end module
program main
use state
implicit none
call change(counter(2:4:2))
print *,counter
end program
