module m
implicit none
integer, parameter :: dp = kind(1.0d0)
contains
function mean(x) result(y)
real(kind=dp), intent(in) :: x(:)
real(kind=dp)             :: y
y = sum(x)/size(x)
end function mean
end module m

program main
use m
implicit none
real(kind=dp) :: x(1000)
call random_number(x)
print*,mean(x)
end program main
