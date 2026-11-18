module operations
implicit none

interface twice
 module procedure twice_int, twice_real
end interface
contains
elemental integer function twice_int(x) result(y)
integer, intent(in) :: x
y=2*x
end function
elemental real function twice_real(x) result(y)
real, intent(in) :: x
y=2*x
end function
end module
program main
use operations
implicit none
integer::a(3)=[1,2,3]
real::b(2)=[1.25,2.5]
print *,twice(a)
print *,twice(b)
end program
