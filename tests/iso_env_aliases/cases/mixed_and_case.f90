program p
USE, INTRINSIC :: ISO_FORTRAN_ENV, ONLY : ReAl32, DP => REAL64, INT32, LONG => INT64
implicit none
real(dp)::x=3.0_dp
print *,real32,dp,int32,long,x
end program
