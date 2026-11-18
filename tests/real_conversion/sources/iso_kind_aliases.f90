program p
use, intrinsic :: iso_fortran_env, only: sp=>real32, dp=>real64
implicit none
real(dp)::x=1.23456789012345_dp
print *,kind(real(x,sp)),kind(real(17,dp)),real(kind=dp,a=17)
end program p
