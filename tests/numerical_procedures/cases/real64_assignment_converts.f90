program main
use, intrinsic :: iso_fortran_env, only : real64
implicit none
integer, parameter :: dp=real64
real(dp) :: a,c
real :: b
a=1.0_dp/3.0_dp
b=a
c=b
print '(3es24.16)',a,b,c
end program main
