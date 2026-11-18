program main
use, intrinsic :: iso_fortran_env, only : real64
implicit none
integer, parameter :: dp=real64
real(dp) :: x
x=1.0_dp+1.0e-12_dp
print *,x-1.0_dp
end program main
