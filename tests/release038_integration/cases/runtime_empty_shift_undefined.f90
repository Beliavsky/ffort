program integration_main
use,intrinsic::iso_fortran_env,only:dp=>real64
implicit none
real(dp)::a(0)
integer::s
write(*,'(a)')'before'
write(*,'(i0)')size(cshift(erfc_scaled(a),s))
end program
