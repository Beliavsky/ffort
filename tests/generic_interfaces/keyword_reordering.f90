module operations
implicit none

interface twice
module procedure ints,reals
end interface
contains
integer function ints(left,right) result(y)
integer,intent(in)::left,right
y=10*left+right
end function
real function reals(left,right) result(y)
real,intent(in)::left,right
y=10*left+right
end function
end module
program main
use operations
implicit none
print *, twice(right=2,left=3), twice(1.5,right=2.5)
end program
