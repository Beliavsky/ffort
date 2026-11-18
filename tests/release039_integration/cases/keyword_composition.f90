! Synthetic release039 integration fixture; independently authored.
program main
use,intrinsic::iso_fortran_env,only:sp=>real32,dp=>real64,ik=>int64,qp=>real128
implicit none
real(dp)::x
x=0._dp
if(bessel_jn(x=x,n=0_ik)/=1._dp)error stop 1
if(anint(kind=sp,a=bessel_jn(x=x,n=1_ik))/=0._sp)error stop 2
if(aint(kind=dp,a=asinh(x=erf(x=x)))/=0._dp)error stop 3
if(acosh(x=1._dp)/=0._dp)error stop 4
write(*,'(a)')'ok'
end program
