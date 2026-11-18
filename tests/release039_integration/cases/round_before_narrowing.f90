! Synthetic release039 integration fixture; independently authored.
program main
use,intrinsic::iso_fortran_env,only:sp=>real32,dp=>real64,ik=>int64,qp=>real128
implicit none
real(dp)::x,y
x=1.999999999999_dp
y=0.499999999999_dp
write(*,'(2f6.1)')aint(x,sp),anint(y,sp)
end program
