program main
use, intrinsic :: iso_fortran_env, only : real64
implicit none
integer, parameter :: dp=real64
real(dp) :: a(5)
a=1.25_dp
call change(a(5:1:-2))
print *,a
contains
subroutine change(x)
real(dp), intent(inout) :: x(:)
x=x+1.0_dp
end subroutine change
end program main
