module operations
implicit none
interface twice
integer function twice_int(x)
integer,intent(in)::x
end function
end interface
end module
program main
use operations
implicit none
end program
