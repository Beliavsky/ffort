module operations
implicit none

interface twice
module procedure twice_int,another
end interface
contains
integer function twice_int(x) result(y)
integer, intent(in) :: x
y=2*x
end function
real function twice_real(x) result(y)
real, intent(in) :: x
y=2*x
end function
integer function another(x) result(y)
integer,intent(in)::x
y=x
end function
end module
program main
use operations
implicit none
print *,twice(3)
end program
