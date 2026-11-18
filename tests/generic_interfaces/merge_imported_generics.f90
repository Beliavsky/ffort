module integers
implicit none
interface twice
module procedure twice_int
end interface
contains
integer function twice_int(x) result(y)
integer,intent(in)::x
y=2*x
end function
end module
module reals
implicit none
interface twice
module procedure twice_real
end interface
contains
real function twice_real(x) result(y)
real,intent(in)::x
y=2*x
end function
end module
program main
use integers,only:twice
use reals,only:twice
implicit none
print *,twice(4),twice(2.5)
end program
