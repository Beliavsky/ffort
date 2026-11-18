module m

contains
function twice(x) result(y)
real,intent(in) :: x
real :: y
integer :: counter=0
counter=counter+1
y=x+counter
end function twice
end module m
program main
use m
implicit none

print *, twice(2.3)
end program main
