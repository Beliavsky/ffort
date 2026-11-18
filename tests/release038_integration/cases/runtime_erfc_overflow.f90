program integration_main
use,intrinsic::iso_fortran_env,only:dp=>real64
implicit none
real(dp)::a(2)
a=[0._dp,-27._dp]
write(*,'(a)')'before'
write(*,*)cshift(erfc_scaled(a),1)
end program
