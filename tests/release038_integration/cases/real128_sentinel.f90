program integration_main
use,intrinsic::iso_fortran_env,only:q=>real128,dp=>real64
implicit none
write(*,'(i0,1x,i0)')q,kind(erfc_scaled(1._dp))
end program
