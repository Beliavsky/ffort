module state
implicit none
integer::counter=2
contains
pure subroutine change()
call put(counter)
end subroutine
pure subroutine put(x)
integer,intent(out)::x
x=3
end subroutine
end module
program main
use state
implicit none
call change()
end program
