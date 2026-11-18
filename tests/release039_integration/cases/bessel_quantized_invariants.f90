! Synthetic release039 integration fixture; independently authored.
program main
use,intrinsic::iso_fortran_env,only:sp=>real32,dp=>real64,ik=>int64,qp=>real128
implicit none
real(dp)::x
x=1._dp
if(anint(1000._dp*bessel_j0(x))/=765._dp)error stop 1
if(anint(1000._dp*bessel_j1(x))/=440._dp)error stop 2
if(anint(1000._dp*bessel_y0(x))/=88._dp)error stop 3
if(anint(1000._dp*bessel_y1(x))/=-781._dp)error stop 4
if(anint(1000._dp*bessel_jn(2_ik,x))/=115._dp)error stop 5
if(anint(1000._dp*bessel_yn(2_ik,x))/=-1651._dp)error stop 6
if(anint(1000._dp*erf(x))/=843._dp)error stop 7
write(*,'(a)')'ok'
end program
