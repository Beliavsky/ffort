! Synthetic release039 integration fixture; independently authored.
program main
use,intrinsic::iso_fortran_env,only:sp=>real32,dp=>real64,ik=>int64,qp=>real128
implicit none

write(*,'(2f6.1)')aint(1.999999999999_dp,sp),anint(0.499999999999_dp,sp)
end program
