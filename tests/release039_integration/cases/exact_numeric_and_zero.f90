! Synthetic release039 integration fixture; independently authored.
program main
use,intrinsic::iso_fortran_env,only:sp=>real32,dp=>real64,ik=>int64,qp=>real128
implicit none
real(dp)::x(4)
x=[-0._dp,0._dp,-0.25_dp,0.25_dp]
write(*,'(4f6.1)')aint(x)
write(*,'(4f6.1)')anint(x)
end program
