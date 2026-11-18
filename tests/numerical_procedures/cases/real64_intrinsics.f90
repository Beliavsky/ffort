program main
use, intrinsic :: iso_fortran_env, only : real64
implicit none
integer, parameter :: dp=real64
print *,exp(1.0_dp),log(2.0_dp),sqrt(2.0_dp),erfc(1.0_dp),abs(-2.0_dp)
print *,max(-5.0_dp,1.0_dp,3.0_dp,2.0_dp)
end program main
