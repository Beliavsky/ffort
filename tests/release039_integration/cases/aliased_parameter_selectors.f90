! Synthetic release039 integration fixture; independently authored.
program main
use,intrinsic::iso_fortran_env,only:sp=>real32,dp=>real64,ik=>int64,qp=>real128
implicit none
integer(ik),parameter::k=sp
real(dp),parameter::a=1.75_dp
if(kind(aint(a,kind=k))/=sp)error stop 1
if(kind(anint(a,dp))/=dp)error stop 2
if(minexponent(aint(a,k))/=-125)error stop 3
if(maxexponent(anint(a,dp))/=1024)error stop 4
if(aint(a,k)/=1._sp.or.anint(a,dp)/=2._dp)error stop 5
write(*,'(a)')'ok'
end program
