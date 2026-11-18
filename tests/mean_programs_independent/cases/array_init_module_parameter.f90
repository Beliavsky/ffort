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
use m, only: dp,mean
implicit none
real(dp)::aa(3)=[10._dp,20._dp,30._dp]
print *,kind(aa),mean(aa)
end program
