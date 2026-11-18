! Synthetic release039 integration fixture; independently authored.
program main
use,intrinsic::iso_fortran_env,only:sp=>real32,dp=>real64,ik=>int64,qp=>real128
implicit none
real(dp)::aint,erf,anint(2),bessel_j0(2)
integer::minexponent,maxexponent
aint=4._dp
anint=[1._dp,2._dp]
erf=3._dp
bessel_j0=[4._dp,5._dp]
minexponent=6
maxexponent=7
if(aint+erf+anint(2)+bessel_j0(1)/=13._dp)error stop 1
if(minexponent+maxexponent/=13)error stop 2
write(*,'(a)')'ok'
end program
