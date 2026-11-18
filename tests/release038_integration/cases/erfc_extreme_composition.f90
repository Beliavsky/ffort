program integration_main
use,intrinsic::iso_fortran_env,only:sp=>real32,dp=>real64
implicit none
real(sp)::a(2),b(2)
real(dp)::c(2),d(2)
a=[huge(1._sp),-9.3824138641357421875_sp]
c=[huge(1._dp),-26.628735713751489_dp]
b=cshift(erfc_scaled(a),1)
d=cshift(erfc_scaled(c),1)
write(*,*)b
write(*,*)d
end program
