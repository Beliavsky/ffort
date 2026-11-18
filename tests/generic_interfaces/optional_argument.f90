module operations
implicit none

interface twice
module procedure twice_int
end interface
contains
integer function twice_int(x,y) result(z)
integer,intent(in)::x
integer,optional,intent(in)::y
z=2*x
end function
end module
program main
use operations
implicit none
print *,twice(3)
end program
