program p
use, intrinsic :: iso_fortran_env, only: &
& sp => real32, &
! preserved source mapping
& dp => real64
implicit none
print *,sp,dp
end program
