module operations
implicit none

interface twice
module procedure small,large
end interface
contains
integer(kind=4) function small(x) result(y)
integer(kind=4),intent(in)::x
y=2*x
end function
integer(kind=8) function large(x) result(y)
integer(kind=8),intent(in)::x
y=3*x
end function
end module
program main
use operations
implicit none
print *,twice(4_4),twice(4_8)
end program
