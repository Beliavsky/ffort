! Synthetic release039 integration fixture; independently authored.
program main
use,intrinsic::iso_fortran_env,only:sp=>real32,dp=>real64,ik=>int64,qp=>real128
implicit none
real(dp)::x(2,0)
integer::n(2,0)
if(any(shape(aint(acosh(x),sp))/=[2,0]))error stop 1
if(size(bessel_yn(n,x))/=0)error stop 2
if(size(cshift(erf(x),1,dim=1))/=0)error stop 3
if(maxexponent(anint(x,sp))/=128)error stop 4
write(*,'(a)')'ok'
end program
