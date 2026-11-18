program integration_main
use,intrinsic::iso_fortran_env,only:dp=>real64,dp=>int64
implicit none
real(dp)::a(2)
a=0
print *,erfc_scaled(cshift(a,1))
end program
