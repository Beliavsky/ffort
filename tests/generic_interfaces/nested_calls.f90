module operations
implicit none

interface twice
 module procedure twice_int, twice_real
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
end module
program main
use operations
implicit none
print *, twice(twice(3)), twice(twice(1.25))
end program
