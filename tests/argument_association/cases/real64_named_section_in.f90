program main
use, intrinsic :: iso_fortran_env, only : real64
implicit none
integer, parameter :: dp=real64
real(dp) :: a(5)
a=1.25_dp
print *,inspect(a(5:1:-2))
contains
real(dp) function inspect(x) result(r)
real(dp), intent(in) :: x(:)
r=x(1)+x(3)
end function inspect
end program main
