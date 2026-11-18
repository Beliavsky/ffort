program integration_main
use,intrinsic::iso_fortran_env,only:dp=>real64,wide=>int64
implicit none
real(dp)::a(2,3),b(2,3)
integer(wide)::s(2)
a=reshape([0._dp,0.5_dp,1._dp,2._dp,3._dp,4._dp],[2,3])
s=[1_wide,-1_wide]
b=cshift(dim=2_wide,shift=s,array=erfc_scaled(x=a))
write(*,*)b
end program
