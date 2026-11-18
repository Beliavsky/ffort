! Synthetic release039 integration fixture; independently authored.
program main
use,intrinsic::iso_fortran_env,only:sp=>real32,dp=>real64,ik=>int64,qp=>real128
implicit none
real(dp)::x,z
real(sp)::zero
if(minexponent(aint(x,sp))/=-125)error stop 1
if(maxexponent(anint(x,dp))/=1024)error stop 2
if(minexponent(bessel_yn(999,acosh(x)))/=-1021)error stop 3
if(maxexponent(erf(1._sp/zero))/=128)error stop 4
if(kind(asinh(1._dp/z))/=dp)error stop 5
write(*,'(a)')'ok'
end program
