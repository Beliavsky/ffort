! Synthetic release039 integration fixture; independently authored.
program main
use,intrinsic::iso_fortran_env,only:sp=>real32,dp=>real64,ik=>int64,qp=>real128
implicit none

write(*,'(6i8)')minexponent(0._sp),maxexponent(0._sp), &
minexponent(0._dp),maxexponent(0._dp),kind(aint(1._dp,sp)),kind(anint(1._sp,dp))
end program
