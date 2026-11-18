module m

contains
function sum2(a,b) result(y)
integer, intent(in) :: a,b
integer :: y
y=a+b
end function sum2
end module m
program main
use m
implicit none
integer :: n=7
print *, sum2(n,n),n
end program main
