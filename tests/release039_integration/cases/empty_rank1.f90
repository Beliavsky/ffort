! Synthetic release039 integration fixture; independently authored.
program main
use,intrinsic::iso_fortran_env,only:sp=>real32,dp=>real64,ik=>int64,qp=>real128
implicit none
real(dp)::x(0)
if(size(anint(asinh(erf(x)),sp))/=0)error stop 1
if(size(bessel_jn(33,x))/=0)error stop 2
if(size(cshift(aint(x,dp),1))/=0)error stop 3
if(minexponent(bessel_y0(x))/=-1021)error stop 4
write(*,'(a)')'ok'
end program
