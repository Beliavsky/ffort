program integration_main
use,intrinsic::iso_fortran_env,only:sp=>real32
implicit none
real(sp)::a(4),b(4)
a=[-1._sp,0._sp,0.5_sp,2._sp]
b=erfc_scaled(cshift(a,1))
write(*,*)b
end program
