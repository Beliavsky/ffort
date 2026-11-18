module operations
implicit none
private
public :: twice
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
use operations, only: twice
implicit none
print *, twice(6), twice(0.75)
end program
